#!/usr/bin/env python3
"""
Create GitHub issue for failed merge conflict resolution.
This script creates a detailed issue when automatic merge resolution fails.
"""

import os
import sys
import json
import argparse
import requests
import logging
from datetime import datetime
from typing import Dict, List, Optional, Tuple
from urllib.parse import urlparse

class MergeConflictIssueCreator:
    """Creates GitHub issues for failed merge conflict resolution."""
    
    # Security constraints
    ALLOWED_SCHEMES = {'https'}
    ALLOWED_HOSTS = {'api.github.com'}
    HTTP_TIMEOUT = 30
    
    def __init__(self, github_token: str):
        """Initialize the issue creator."""
        self.logger = logging.getLogger(__name__)
        self.github_token = self._validate_token(github_token)
        
        # Get repository information from environment
        self.repo_owner = os.getenv('GITHUB_REPOSITORY_OWNER', '')
        repo_full = os.getenv('GITHUB_REPOSITORY', '')
        
        if '/' in repo_full:
            self.repo_name = repo_full.split('/')[-1]
        else:
            self.repo_name = repo_full
            
        if not self.repo_owner or not self.repo_name:
            raise ValueError("Repository information not found in environment")
            
        self.api_base = f"https://api.github.com/repos/{self.repo_owner}/{self.repo_name}"
        
        # Set up HTTP session with security constraints
        self.session = requests.Session()
        self.session.headers.update({
            'Authorization': f'token {self.github_token}',
            'Accept': 'application/vnd.github.v3+json',
            'User-Agent': 'GitHub-Auto-Merge-Conflict-Bot/1.0'
        })
        
    def _validate_token(self, token: str) -> str:
        """Validate and sanitize the GitHub token."""
        if not token:
            raise ValueError("GitHub token is required")
        
        # Basic token format validation
        if not token.startswith(('ghp_', 'github_pat_')):
            self.logger.warning("Token does not match expected GitHub format")
            
        return token.strip()
        
    def _validate_url(self, url: str) -> bool:
        """Validate URL against security constraints."""
        try:
            parsed = urlparse(url)
            return (
                parsed.scheme in self.ALLOWED_SCHEMES and
                parsed.hostname in self.ALLOWED_HOSTS
            )
        except Exception:
            return False
            
    def _safe_request(self, method: str, url: str, **kwargs) -> requests.Response:
        """Make a safe HTTP request with validation."""
        if not self._validate_url(url):
            raise ValueError(f"URL not allowed: {url}")
            
        kwargs.setdefault('timeout', self.HTTP_TIMEOUT)
        
        try:
            response = self.session.request(method, url, **kwargs)
            response.raise_for_status()
            return response
        except requests.exceptions.RequestException as e:
            self.logger.error(f"HTTP request failed: {e}")
            raise
            
    def _read_file_safely(self, filepath: str) -> str:
        """Safely read file content with error handling."""
        try:
            if os.path.exists(filepath):
                with open(filepath, 'r', encoding='utf-8') as f:
                    return f.read().strip()
            else:
                self.logger.warning(f"File not found: {filepath}")
                return ""
        except Exception as e:
            self.logger.error(f"Error reading file {filepath}: {e}")
            return f"Error reading file: {e}"
            
    def _get_conflicted_files(self, filepath: str) -> List[str]:
        """Get list of conflicted files from file."""
        content = self._read_file_safely(filepath)
        if content:
            return [line.strip() for line in content.split('\n') if line.strip()]
        return []
        
    def _check_existing_issue(self, title_pattern: str) -> Optional[int]:
        """Check if an issue with similar title already exists."""
        try:
            # Search for existing issues with merge conflict in title
            search_url = f"{self.api_base}/issues"
            params = {
                'state': 'open',
                'labels': 'merge-conflict,automated',
                'per_page': 50
            }
            
            response = self._safe_request('GET', search_url, params=params)
            issues = response.json()
            
            # Look for recent merge conflict issues
            for issue in issues:
                if 'merge conflict' in issue['title'].lower():
                    # Check if it's recent (within last 7 days)
                    created_at = datetime.fromisoformat(issue['created_at'].replace('Z', '+00:00'))
                    now = datetime.now(created_at.tzinfo)
                    days_old = (now - created_at).days
                    
                    if days_old < 7:
                        self.logger.info(f"Found recent merge conflict issue: #{issue['number']}")
                        return issue['number']
                        
        except Exception as e:
            self.logger.error(f"Error checking existing issues: {e}")
            
        return None
        
    def create_issue(self, target_branch: str, error_type: str, 
                    merge_output_file: str, resolve_output_file: str,
                    conflicted_files_file: str, git_status_file: str) -> bool:
        """Create a GitHub issue for the failed merge."""
        
        timestamp = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC')
        
        # Read log files
        merge_output = self._read_file_safely(merge_output_file)
        resolve_output = self._read_file_safely(resolve_output_file)
        git_status = self._read_file_safely(git_status_file)
        conflicted_files = self._get_conflicted_files(conflicted_files_file)
        
        # Create issue title and body
        title = f"🔀 Automatic merge conflict resolution failed - {target_branch} → clone-me"
        
        # Check for existing issue
        existing_issue = self._check_existing_issue(title)
        if existing_issue:
            self.logger.info(f"Updating existing issue #{existing_issue} instead of creating new one")
            return self._update_existing_issue(existing_issue, target_branch, error_type, 
                                            merge_output, resolve_output, git_status, 
                                            conflicted_files, timestamp)
        
        # Create detailed issue body
        body = self._create_issue_body(target_branch, error_type, merge_output, 
                                     resolve_output, git_status, conflicted_files, timestamp)
        
        # Create the issue
        try:
            issue_data = {
                'title': title,
                'body': body,
                'labels': ['merge-conflict', 'automated', 'help-wanted'],
                'assignees': []  # Could be configured to assign to specific users
            }
            
            url = f"{self.api_base}/issues"
            response = self._safe_request('POST', url, json=issue_data)
            
            issue = response.json()
            issue_number = issue['number']
            issue_url = issue['html_url']
            
            self.logger.info(f"Created issue #{issue_number}: {issue_url}")
            print(f"✅ Created merge conflict issue: #{issue_number}")
            print(f"🔗 Issue URL: {issue_url}")
            
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to create issue: {e}")
            print(f"❌ Failed to create issue: {e}")
            return False
            
    def _update_existing_issue(self, issue_number: int, target_branch: str, 
                              error_type: str, merge_output: str, resolve_output: str,
                              git_status: str, conflicted_files: List[str], 
                              timestamp: str) -> bool:
        """Update existing issue with new failure information."""
        try:
            # Get current issue
            url = f"{self.api_base}/issues/{issue_number}"
            response = self._safe_request('GET', url)
            current_issue = response.json()
            
            # Create update comment
            comment_body = f"""## 🔄 New Merge Conflict Failure - {timestamp}

**Target Branch:** `{target_branch}` → `clone-me`
**Error Type:** `{error_type}`

### Conflicted Files
{self._format_conflicted_files(conflicted_files)}

### Recent Logs
<details>
<summary>Git Status Output</summary>

```
{git_status[:2000]}{'...' if len(git_status) > 2000 else ''}
```
</details>

<details>
<summary>Resolve Script Output</summary>

```
{resolve_output[:2000]}{'...' if len(resolve_output) > 2000 else ''}
```
</details>

---
*This comment was automatically generated by the Auto-Merge Conflict Resolution workflow.*
"""

            # Add comment to existing issue
            comment_url = f"{self.api_base}/issues/{issue_number}/comments"
            comment_data = {'body': comment_body}
            
            self._safe_request('POST', comment_url, json=comment_data)
            
            self.logger.info(f"Updated existing issue #{issue_number} with new failure")
            print(f"✅ Updated existing merge conflict issue: #{issue_number}")
            
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to update existing issue: {e}")
            return False
            
    def _create_issue_body(self, target_branch: str, error_type: str, 
                          merge_output: str, resolve_output: str, git_status: str,
                          conflicted_files: List[str], timestamp: str) -> str:
        """Create the detailed issue body."""
        
        return f"""## 🔀 Automatic Merge Conflict Resolution Failed

The automated merge conflict resolution workflow failed to merge `{target_branch}` into `clone-me`.

**Timestamp:** {timestamp}  
**Error Type:** `{error_type}`  
**Target Branch:** `{target_branch}` → `clone-me`

### 📋 Summary

The GitHub Action attempted to automatically resolve merge conflicts using the `resolve-clone-me-conflicts.sh` script, but the process failed. Manual intervention is required to complete the merge.

### 🔍 Conflicted Files

{self._format_conflicted_files(conflicted_files)}

### 📚 Resolution Steps

Follow the [Manual Merge Guide](./MANUAL_MERGE_GUIDE.md) to resolve these conflicts:

1. **Start the merge:**
   ```bash
   git checkout clone-me
   git merge {target_branch} --allow-unrelated-histories
   ```

2. **Resolve conflicts using the provided script:**
   ```bash
   ./resolve-clone-me-conflicts.sh
   ```

3. **If script fails, resolve manually:**
   - Edit conflicted files to resolve merge markers
   - Use the conflict resolution strategies in the guide
   - Test your changes

4. **Complete the merge:**
   ```bash
   git add .
   git commit -m "Merge {target_branch} into clone-me - resolve conflicts"
   git push -u origin clone-me
   ```

### 🛠️ Quick Reference

- **[Manual Merge Guide](./MANUAL_MERGE_GUIDE.md)** - Complete step-by-step instructions
- **[Quick Reference](./MERGE_QUICK_REFERENCE.md)** - Fast resolution guide for experienced users
- **[Implementation Guide](./MANUAL_MERGE_IMPLEMENTATION.md)** - Technical details and testing

### 🔧 Troubleshooting

If you encounter issues:

1. **Check script permissions:** `chmod +x resolve-clone-me-conflicts.sh`
2. **Validate git state:** `git status` and `git ls-files -u`
3. **Reset if needed:** `git merge --abort` to start over
4. **Review logs:** Check the detailed output below

### 📊 Detailed Logs

<details>
<summary>🔍 Git Status Output</summary>

```
{git_status}
```
</details>

<details>
<summary>🔧 Merge Output</summary>

```
{merge_output[:3000]}{'...\n[truncated]' if len(merge_output) > 3000 else ''}
```
</details>

<details>
<summary>🛠️ Conflict Resolution Script Output</summary>

```
{resolve_output[:3000]}{'...\n[truncated]' if len(resolve_output) > 3000 else ''}
```
</details>

### 🎯 Next Steps

- [ ] Review the conflicted files and understand the conflicts
- [ ] Follow the manual resolution steps above
- [ ] Test the merged code to ensure functionality
- [ ] Close this issue once the merge is completed successfully

---

*This issue was automatically created by the Auto-Merge Conflict Resolution workflow. The workflow runs weekly and on manual trigger to help maintain synchronization between branches.*

**Need help?** Check the documentation links above or ask in the repository discussions.
"""

    def _format_conflicted_files(self, conflicted_files: List[str]) -> str:
        """Format the list of conflicted files for display."""
        if not conflicted_files:
            return "*No specific conflicted files detected.*"
            
        formatted = []
        for file in conflicted_files[:10]:  # Limit to first 10 files
            # Try to categorize the file
            if file.startswith('.github/scripts/'):
                category = "🐍 Python Script"
            elif file.startswith('.github/workflows/'):
                category = "⚙️ GitHub Workflow"
            elif file.endswith('.sh'):
                category = "🔧 Shell Script"
            elif file == 'Makefile':
                category = "🏗️ Build Configuration"
            elif file.endswith('.md'):
                category = "📝 Documentation"
            else:
                category = "📄 File"
                
            formatted.append(f"- {category} `{file}`")
            
        if len(conflicted_files) > 10:
            formatted.append(f"- *... and {len(conflicted_files) - 10} more files*")
            
        return '\n'.join(formatted)


def main():
    """Main function to handle command line execution."""
    parser = argparse.ArgumentParser(description='Create GitHub issue for failed merge resolution')
    parser.add_argument('--target-branch', required=True, help='Target branch that failed to merge')
    parser.add_argument('--error-type', required=True, help='Type of error that occurred')
    parser.add_argument('--merge-output', required=True, help='Path to merge output log file')
    parser.add_argument('--resolve-output', required=True, help='Path to resolve script output log file')
    parser.add_argument('--conflicted-files', required=True, help='Path to conflicted files list')
    parser.add_argument('--git-status', required=True, help='Path to git status output')
    
    args = parser.parse_args()
    
    # Set up logging
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s'
    )
    
    try:
        # Get GitHub token from environment
        github_token = os.getenv('GITHUB_TOKEN')
        if not github_token:
            print("❌ GITHUB_TOKEN environment variable is required")
            sys.exit(1)
            
        # Create issue creator and process
        creator = MergeConflictIssueCreator(github_token)
        
        success = creator.create_issue(
            target_branch=args.target_branch,
            error_type=args.error_type,
            merge_output_file=args.merge_output,
            resolve_output_file=args.resolve_output,
            conflicted_files_file=args.conflicted_files,
            git_status_file=args.git_status
        )
        
        if success:
            print("✅ Merge conflict issue creation completed successfully")
            sys.exit(0)
        else:
            print("❌ Failed to create merge conflict issue")
            sys.exit(1)
            
    except Exception as e:
        logging.error(f"Fatal error: {e}")
        print(f"❌ Fatal error: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()