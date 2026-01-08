#!/usr/bin/env python3
"""
Test script to verify the documentation structure parsing.
This script doesn't require external dependencies and validates inputs.
"""

import json
import re
import logging
from typing import Dict, List, Optional
from dataclasses import dataclass

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

class StructureTester:
    # Valid URL schemes
    ALLOWED_SCHEMES = {'https'}
    # Allowed hosts
    ALLOWED_HOSTS = {'www.gnu.org'}
    
    def __init__(self):
        logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger(__name__)
        
    def _validate_url(self, url: str) -> bool:
        """Basic URL validation for testing."""
        if not url or not isinstance(url, str):
            return False
        
        # Basic scheme check
        if not url.startswith('https://'):
            return False
            
        # Basic host check
        if 'www.gnu.org' not in url:
            return False
            
        return True
        
    def _sanitize_key(self, key: str) -> str:
        """Sanitize dictionary keys."""
        if not isinstance(key, str):
            raise ValueError("Key must be a string")
        
        # Remove dangerous characters
        safe_key = re.sub(r'[<>"\'/\\]', '', key)
        return safe_key[:100]  # Limit length
        
    def parse_documentation_structure(self) -> List[IssueItem]:
        """Parse the open issues documentation structure."""
        
        # Simplified structure for testing
        structure_data = {
            "advantages": {"url": "https://www.gnu.org/software/hurd/advantages.html", "level": 0},
            "capability": {"url": "https://www.gnu.org/software/hurd/capability.html", "level": 0},
            "challenges": {"url": "https://www.gnu.org/software/hurd/challenges.html", "level": 0},
            "community": {
                "url": "https://www.gnu.org/software/hurd/community.html", 
                "level": 0,
                "children": {
                    "gsoc": {
                        "url": "https://www.gnu.org/software/hurd/community/gsoc.html",
                        "level": 1
                    }
                }
            }
        }
        
        # Validate structure before processing
        self._validate_structure(structure_data)
        
        return self._flatten_structure(structure_data)
    
    def _validate_structure(self, structure: Dict) -> None:
        """Validate the structure data."""
        if not isinstance(structure, dict):
            raise ValueError("Structure must be a dictionary")
        
        for key, data in structure.items():
            # Validate key
            self._sanitize_key(key)
            
            if isinstance(data, dict):
                if 'url' in data:
                    if not self._validate_url(data['url']):
                        raise ValueError(f"Invalid URL for {key}: {data['url']}")
                
                if 'level' in data:
                    if not isinstance(data['level'], int) or data['level'] < 0:
                        raise ValueError(f"Invalid level for {key}: {data['level']}")
                
                if 'children' in data:
                    self._validate_structure(data['children'])
    
    def _flatten_structure(self, structure: Dict, parent: str = None) -> List[IssueItem]:
        """Flatten the nested structure into a list of IssueItem objects."""
        items = []
        
        for key, data in structure.items():
            if isinstance(data, dict) and 'url' in data:
                # Sanitize title
                safe_title = self._format_title(key)
                
                item = IssueItem(
                    title=safe_title,
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
        safe_key = self._sanitize_key(key)
        return safe_key.replace('_', ' ').title()
    
    def generate_actionable_steps(self, item: IssueItem) -> List[str]:
        """Generate actionable steps for an issue based on its type and level."""
        steps = []
        
        # Validate item
        if not isinstance(item, IssueItem):
            raise ValueError("Item must be an IssueItem instance")
        
        # Common steps for all items
        steps.append(f"Review the documentation at: {item.url}")
        steps.append("Analyze current implementation status")
        steps.append("Identify gaps and missing components")
        
        # Level-specific steps
        if item.level == 0:  # Top-level categories
            steps.extend([
                "Create comprehensive documentation outline",
                "Define scope and objectives",
                "Establish success criteria",
                "Assign priority levels to sub-components"
            ])
        elif item.level == 1:  # Major components
            steps.extend([
                "Review existing implementation",
                "Document current limitations",
                "Propose improvements and enhancements",
                "Create test cases and validation criteria"
            ])
        elif item.level >= 2:  # Specific features/issues
            steps.extend([
                "Implement core functionality",
                "Write unit tests",
                "Create integration tests",
                "Update documentation",
                "Submit for code review"
            ])
        
        return steps
    
    def test_structure_parsing(self):
        """Test the structure parsing functionality."""
        try:
            self.logger.info("Testing documentation structure parsing...")
            
            items = self.parse_documentation_structure()
            self.logger.info(f"Found {len(items)} items to process")
            
            # Print first few items for verification
            self.logger.info("First 5 items:")
            for i, item in enumerate(items[:5]):
                self.logger.info(f"{i+1}. {item.title} (Level: {item.level}, Parent: {item.parent})")
                steps = self.generate_actionable_steps(item)
                self.logger.info(f"   Actionable steps: {len(steps)} steps generated")
            
            # Save the structure to a JSON file for reference
            output_data = []
            for item in items:
                output_data.append({
                    'title': item.title,
                    'url': item.url,
                    'level': item.level,
                    'parent': item.parent,
                    'actionable_steps': self.generate_actionable_steps(item)
                })
            
            # Sanitize filename
            filename = 'test_structure_output.json'
            
            with open(filename, 'w', encoding='utf-8') as f:
                json.dump(output_data, f, indent=2, ensure_ascii=False)
            
            self.logger.info(f"Saved structure to {filename}")
            self.logger.info("Structure parsing test completed successfully!")
            
        except Exception as e:
            self.logger.error(f"Test failed: {e}")
            raise

if __name__ == "__main__":
    try:
        tester = StructureTester()
        tester.test_structure_parsing()
    except Exception as e:
        logging.error(f"Script failed: {e}")
        exit(1)
