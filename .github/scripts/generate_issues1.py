#!/usr/bin/env python3
"""
Generate GitHub issues from open issues documentation structure.
This script parses the nested structure and creates issues with actionable steps.
"""

import os
import re
import json
import requests
import yaml
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass
from urllib.parse import urlparse, urljoin
import urllib3
import logging

@dataclass
class IssueItem:
    """Represents an issue item from the documentation."""
    title: str
    url: str
    level: int
    parent: Optional[str] = None
    children: List[str] = None
    
    def __post_init__(self):
        if self.children is None:
            self.children = []

class IssueGenerator:
    # Allowed URL schemes for security
    ALLOWED_SCHEMES = {'https'}
    # Allowed hosts for GitHub API and documentation
    ALLOWED_HOSTS = {'api.github.com', 'www.gnu.org'}
    # Maximum timeout for HTTP requests
    HTTP_TIMEOUT = 30
    
    def __init__(self, github_token: Optional[str] = None):
        # Set up logging
        logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger(__name__)
        
        # Validate and sanitize environment variables
        self.github_token = self._validate_token(github_token or os.getenv('GITHUB_TOKEN'))
        self.repo_owner = self._validate_repo_component(
            os.getenv('GITHUB_REPOSITORY_OWNER', 'gnu')
        )
        repo_full = os.getenv('GITHUB_REPOSITORY', 'gnu/hurd')
        if '/' in repo_full:
            self.repo_name = self._validate_repo_component(repo_full.split('/')[-1])
        else:
            self.repo_name = self._validate_repo_component(repo_full)
        
        # Construct API base URL safely
        self.api_base = f"https://api.github.com/repos/{self.repo_owner}/{self.repo_name}"
        
        # Validate the constructed URL
        self._validate_url(self.api_base)
    
    def _validate_token(self, token: Optional[str]) -> Optional[str]:
        """Validate GitHub token format."""
        if not token:
            return None
        
        # GitHub tokens should be alphanumeric with underscores
        if not re.match(r'^[a-zA-Z0-9_]+$', token):
            raise ValueError("Invalid GitHub token format")
        
        # Check minimum length (GitHub tokens are typically much longer)
        if len(token) < 10:
            raise ValueError("GitHub token too short")
            
        return token
    
    def _validate_repo_component(self, component: str) -> str:
        """Validate repository owner/name component."""
        if not component:
            raise ValueError("Repository component cannot be empty")
        
        # Repository names should only contain alphanumeric characters, hyphens, and underscores
        if not re.match(r'^[a-zA-Z0-9._-]+$', component):
            raise ValueError(f"Invalid repository component: {component}")
        
        # Prevent path traversal
        if '..' in component or component.startswith('/'):
            raise ValueError(f"Repository component contains invalid characters: {component}")
            
        return component
    
    def _validate_url(self, url: str) -> bool:
        """Validate URL is safe to use."""
        try:
            parsed = urlparse(url)
            
            # Check scheme
            if parsed.scheme not in self.ALLOWED_SCHEMES:
                raise ValueError(f"Disallowed URL scheme: {parsed.scheme}")
            
            # Check host
            if parsed.hostname not in self.ALLOWED_HOSTS:
                raise ValueError(f"Disallowed host: {parsed.hostname}")
            
            return True
        except Exception as e:
            self.logger.error(f"URL validation failed for {url}: {e}")
            raise ValueError(f"Invalid URL: {url}")
    
    def _sanitize_filename(self, filename: str) -> str:
        """Sanitize filename to prevent path traversal."""
        # Remove any path components
        filename = os.path.basename(filename)
        
        # Remove any dangerous characters
        filename = re.sub(r'[<>:"/\\|?*]', '_', filename)
        
        # Ensure it doesn't start with dot or dash
        if filename.startswith('.') or filename.startswith('-'):
            filename = 'file_' + filename
        
        return filename
        
    def parse_documentation_structure(self) -> List[IssueItem]:
        """Parse the open issues documentation structure."""
        
        # This is the structure from the provided documentation
        structure_data = {
            "advantages": {"url": "https://www.gnu.org/software/hurd/advantages.html", "level": 0}
        }
        
        # Validate all URLs in the structure
        self._validate_structure_urls(structure_data)
        
        return self._flatten_structure(structure_data)
    
    def _validate_structure_urls(self, structure: Dict) -> None:
        """Recursively validate all URLs in the structure."""
        for key, data in structure.items():
            if isinstance(data, dict):
                if 'url' in data:
                    self._validate_url(data['url'])
                if 'children' in data:
                    self._validate_structure_urls(data['children'])
    
    def _flatten_structure(self, structure: Dict, parent: str = None) -> List[IssueItem]:
        """Flatten the nested structure into a list of IssueItem objects."""
        items = []
        
        for key, data in structure.items():
            if isinstance(data, dict) and 'url' in data:
                item = IssueItem(
                    title=self._format_title(key),
                    url=data['url'],
                    level=data.get('level', 0),
                    parent=parent
                )
                items.append(item)
                
                # Process children recursively
                if 'children' in data:
                    child_items = self._flatten_structure(data['children'], key)
                    items.extend(child_items)
                    
        return items
    
    def _format_title(self, key: str) -> str:
        """Format the key into a readable title."""
        # Sanitize the key to prevent injection
        safe_key = re.sub(r'[^\w\s-]', '', key)
        return safe_key.replace('_', ' ').title()
    
    def generate_actionable_steps(self, item: IssueItem) -> List[str]:
        """Generate actionable steps for an issue based on its type and level."""
        steps = []
        
        # Common steps for all items
        steps.append(f"Review the documentation at: {item.url}")
        steps.append("Analyze current implementation status")
        steps.append("Identify gaps and missing components")
        
        return steps
    
    def create_issue_body(self, item: IssueItem) -> str:
        """Create the body content for a GitHub issue."""
        steps = self.generate_actionable_steps(item)
        
        body = f"""## Documentation Item: {item.title}

**Source URL:** {item.url}
**Level:** {item.level}
**Parent:** {item.parent if item.parent else 'None'}

### Description
This issue tracks the documentation and implementation work needed for: **{item.title}**

### Actionable Steps
{chr(10).join(f"- [ ] {step}" for step in steps)}
"""
        
        return body
    
    def create_github_issue(self, item: IssueItem) -> Optional[Dict]:
        """Create a GitHub issue for the given item."""
        if not self.github_token:
            self.logger.info(f"Would create issue: {item.title}")
            return None
        
        headers = {
            'Authorization': f'token {self.github_token}',
            'Accept': 'application/vnd.github.v3+json',
            'User-Agent': 'GitHub-Issue-Generator/1.0'
        }
        
        # Sanitize title and body to prevent injection
        safe_title = re.sub(r'[^\w\s-:().]', '', item.title)[:200]  # Limit length
        safe_body = self.create_issue_body(item)
        
        data = {
            'title': f"Documentation: {safe_title}",
            'body': safe_body,
            'labels': ['documentation', 'enhancement', 'automated-issue']
        }
        
        try:
            # Use session for connection pooling and security
            session = requests.Session()
            session.verify = True  # Ensure SSL verification
            
            response = session.post(
                f"{self.api_base}/issues",
                headers=headers,
                json=data,
                timeout=self.HTTP_TIMEOUT
            )
            
            if response.status_code == 201:
                self.logger.info(f"Created issue: {item.title}")
                return response.json()
            else:
                self.logger.error(f"Failed to create issue for {item.title}: {response.status_code}")
                return None
                
        except requests.exceptions.SSLError as e:
            self.logger.error(f"SSL error creating issue for {item.title}: {e}")
            return None
        except requests.exceptions.Timeout as e:
            self.logger.error(f"Timeout creating issue for {item.title}: {e}")
            return None
        except requests.exceptions.RequestException as e:
            self.logger.error(f"Request error creating issue for {item.title}: {e}")
            return None
        except Exception as e:
            self.logger.error(f"Unexpected error creating issue for {item.title}: {e}")
            return None
    
    def run(self):
        """Main execution method."""
        try:
            self.logger.info("Parsing open issues documentation structure...")
            items = self.parse_documentation_structure()
            
            self.logger.info(f"Found {len(items)} items to process")
            
            # Create issues for each item
            created_issues = []
            for item in items:
                issue = self.create_github_issue(item)
                if issue:
                    created_issues.append(issue)
            
            self.logger.info(f"Successfully created {len(created_issues)} issues")
            
            # Save the structure to a JSON file for reference
            output_file = self._sanitize_filename('open_issues_structure.json')
            try:
                with open(output_file, 'w', encoding='utf-8') as f:
                    json.dump([{
                        'title': item.title,
                        'url': item.url,
                        'level': item.level,
                        'parent': item.parent,
                        'actionable_steps': self.generate_actionable_steps(item)
                    } for item in items], f, indent=2, ensure_ascii=False)
                
                self.logger.info(f"Saved structure to {output_file}")
            except (IOError, OSError) as e:
                self.logger.error(f"Error saving structure to file: {e}")
                
        except Exception as e:
            self.logger.error(f"Error in main execution: {e}")
            raise

if __name__ == "__main__":
    try:
        generator = IssueGenerator()
        generator.run()
    except Exception as e:
        logging.error(f"Script failed: {e}")
        exit(1)
