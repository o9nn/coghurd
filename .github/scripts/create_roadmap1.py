#!/usr/bin/env python3
"""
Create an advanced development roadmap with Mermaid and PlantUML diagrams
for the Hurd project, showing architecture and development status.
"""

import os
import json
import re
from typing import Dict, List, Set
from dataclasses import dataclass
from datetime import datetime
import logging

@dataclass
class Component:
    """Represents a Hurd component with status information."""
    name: str
    status: str  # 'complete', 'in-progress', 'planned', 'missing'
    description: str
    dependencies: List[str]
    priority: str  # 'high', 'medium', 'low'
    category: str

class RoadmapGenerator:
    # Valid status values
    VALID_STATUSES = {'complete', 'in-progress', 'planned', 'missing'}
    # Valid priority values
    VALID_PRIORITIES = {'high', 'medium', 'low'}
    # Valid category values
    VALID_CATEGORIES = {
        'microkernel', 'servers', 'translators', 'libraries', 
        'utilities', 'tools', 'boot', 'security', 'optimization',
        'documentation', 'testing'
    }
    
    def __init__(self):
        # Set up logging
        logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger(__name__)
        
        self.components = self._initialize_components()
        
    def _validate_component(self, component: Component) -> Component:
        """Validate component data for security."""
        # Sanitize name and description
        component.name = re.sub(r'[<>"\']', '', component.name)[:100]
        component.description = re.sub(r'[<>"\']', '', component.description)[:500]
        
        # Validate status
        if component.status not in self.VALID_STATUSES:
            raise ValueError(f"Invalid status: {component.status}")
        
        # Validate priority
        if component.priority not in self.VALID_PRIORITIES:
            raise ValueError(f"Invalid priority: {component.priority}")
        
        # Validate category
        if component.category not in self.VALID_CATEGORIES:
            raise ValueError(f"Invalid category: {component.category}")
        
        # Sanitize dependencies
        component.dependencies = [
            re.sub(r'[<>"\']', '', dep)[:50] for dep in component.dependencies
        ]
        
        return component
        
    def _initialize_components(self) -> Dict[str, Component]:
        """Initialize the Hurd components with their current status."""
        components = {
            # Core Microkernel Components
            "gnumach": Component(
                name="GNU Mach Microkernel",
                status="complete",
                description="Core microkernel providing basic OS services",
                dependencies=[],
                priority="high",
                category="microkernel"
            ),
            "mach_interface": Component(
                name="Mach Interface",
                status="complete",
                description="Interface layer for Mach microkernel",
                dependencies=["gnumach"],
                priority="high",
                category="microkernel"
            ),
            
            # Hurd Servers
            "auth": Component(
                name="Authentication Server",
                status="complete",
                description="Handles user authentication and authorization",
                dependencies=["mach_interface"],
                priority="high",
                category="servers"
            ),
            "proc": Component(
                name="Process Server",
                status="complete",
                description="Manages processes and process creation",
                dependencies=["mach_interface", "auth"],
                priority="high",
                category="servers"
            )
        }
        
        # Validate all components
        validated_components = {}
        for key, component in components.items():
            try:
                validated_components[key] = self._validate_component(component)
            except ValueError as e:
                self.logger.error(f"Invalid component {key}: {e}")
                continue
                
        return validated_components
    
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
    
    def generate_mermaid_architecture_diagram(self) -> str:
        """Generate a Mermaid diagram showing the Hurd architecture."""
        # Sanitize component names for Mermaid
        safe_components = {}
        for key, component in self.components.items():
            safe_key = re.sub(r'[^\w]', '_', key)
            safe_name = re.sub(r'[<>"\']', '', component.name)
            safe_components[safe_key] = safe_name
        
        diagram = """```mermaid
graph TB
    %% Hurd Architecture
    subgraph "Microkernel"
        gnumach[GNU Mach]
        mach_interface[Mach Interface]
    end
    
    subgraph "Servers"
        auth[Authentication Server]
        proc[Process Server]
    end
    
    %% Connections
    auth --> mach_interface
    proc --> mach_interface
    mach_interface --> gnumach
```"""
        
        return diagram
    
    def generate_component_status_table(self) -> str:
        """Generate a markdown table showing component status."""
        table = "| Component | Status | Priority | Category | Dependencies |\n"
        table += "|-----------|--------|----------|----------|--------------|\n"
        
        for name, component in self.components.items():
            status_emoji = {
                "complete": "✅",
                "in-progress": "🔄",
                "planned": "📋",
                "missing": "❌"
            }.get(component.status, "❓")
            
            priority_emoji = {
                "high": "🔴",
                "medium": "🟡",
                "low": "🟢"
            }.get(component.priority, "⚪")
            
            # Sanitize all table content
            safe_name = re.sub(r'[|]', '', component.name)
            safe_status = re.sub(r'[|]', '', component.status.title())
            safe_priority = re.sub(r'[|]', '', component.priority.title())
            safe_category = re.sub(r'[|]', '', component.category.title())
            
            deps = ", ".join(re.sub(r'[|]', '', dep) for dep in component.dependencies) if component.dependencies else "None"
            
            table += f"| {safe_name} | {status_emoji} {safe_status} | {priority_emoji} {safe_priority} | {safe_category} | {deps} |\n"
        
        return table
    
    def generate_roadmap_markdown(self) -> str:
        """Generate the complete roadmap markdown document."""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S UTC")
        
        roadmap = f"""# Hurd Development Roadmap

*Generated on: {timestamp}*

## Overview

This roadmap provides a comprehensive view of the Hurd operating system development status, architecture, and future plans. The Hurd is a microkernel-based operating system that implements the POSIX API on top of the GNU Mach microkernel.

## Architecture Overview

### System Architecture

{self.generate_mermaid_architecture_diagram()}

## Component Status

{self.generate_component_status_table()}

## Development Phases

### Phase 1: Core Stability (2024 Q1-Q2)
**Focus:** Complete core system components and improve stability

**Objectives:**
- Complete File System Server implementation
- Enhance Network Server functionality
- Implement performance optimizations
- Add security enhancements
- Improve documentation coverage

## Contributing

To contribute to the Hurd development:

1. Review the current status of components
2. Identify areas where you can contribute
3. Follow the development guidelines
4. Submit patches and improvements
5. Help with documentation and testing

---

*This roadmap is automatically generated and updated regularly. For the most current information, please check the official Hurd documentation and development channels.*
"""
        
        return roadmap
    
    def save_roadmap(self, filename: str = "DEVELOPMENT_ROADMAP.md"):
        """Save the roadmap to a markdown file."""
        try:
            # Sanitize filename
            safe_filename = self._sanitize_filename(filename)
            
            roadmap_content = self.generate_roadmap_markdown()
            
            with open(safe_filename, 'w', encoding='utf-8') as f:
                f.write(roadmap_content)
            
            self.logger.info(f"Roadmap saved to {safe_filename}")
            
        except (IOError, OSError) as e:
            self.logger.error(f"Error saving roadmap: {e}")
            raise
    
    def run(self):
        """Main execution method."""
        try:
            self.logger.info("Generating Hurd development roadmap...")
            self.save_roadmap()
            self.logger.info("Roadmap generation completed!")
            
        except Exception as e:
            self.logger.error(f"Error generating roadmap: {e}")
            raise

if __name__ == "__main__":
    try:
        generator = RoadmapGenerator()
        generator.run()
    except Exception as e:
        logging.error(f"Script failed: {e}")
        exit(1)
