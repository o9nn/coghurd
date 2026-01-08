#!/usr/bin/env python3
"""
Generate comprehensive test catalog from open issues documentation.

This script parses docs/open-issues/open-issues.md and extracts structured
test parameters for each issue, generating both JSON and Scheme output formats
with hooks for cognitive grammar and ggml kernel shapes integration.
"""

import os
import re
import json
import sys
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, asdict
from pathlib import Path


@dataclass
class TestParameter:
    """Represents test parameters for an issue."""
    issue_title: str
    description: str
    impact_area: str
    failure_mode: str
    resolution_criteria: List[str]
    dependencies: List[str]
    category: str
    subcategory: str
    status: str
    solutions: List[str]
    
    # Hooks for future integration
    cognitive_grammar_hooks: Dict[str, Any]
    ggml_kernel_shapes: Dict[str, Any]
    

class TestCatalogGenerator:
    """Generates test catalog from open issues markdown."""
    
    def __init__(self, input_file: str, output_dir: str):
        self.input_file = Path(input_file)
        self.output_dir = Path(output_dir)
        self.test_parameters: List[TestParameter] = []
        self.current_category = ""
        self.current_subcategory = ""
        
    def parse_markdown(self) -> None:
        """Parse the markdown file and extract issue data."""
        with open(self.input_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Split content into sections
        sections = self._split_into_sections(content)
        
        for section in sections:
            self._process_section(section)
    
    def _split_into_sections(self, content: str) -> List[Dict[str, Any]]:
        """Split content into hierarchical sections."""
        lines = content.split('\n')
        sections = []
        current_section = None
        
        for line in lines:
            # Check for headers
            if line.startswith('#'):
                if current_section:
                    sections.append(current_section)
                
                level = len(line) - len(line.lstrip('#'))
                title = line.lstrip('#').strip()
                current_section = {
                    'level': level,
                    'title': title,
                    'content': [],
                    'subsections': []
                }
            elif current_section:
                current_section['content'].append(line)
        
        if current_section:
            sections.append(current_section)
        
        return sections
    
    def _process_section(self, section: Dict[str, Any]) -> None:
        """Process a section and extract test parameters."""
        title = section['title']
        content = '\n'.join(section['content'])
        level = section['level']
        
        # Skip certain sections
        if any(skip in title.lower() for skip in ['known open issues', 'tracking', 'further reading']):
            return
        
        # Set category based on section level and title
        if level == 2:  # Major categories
            self.current_category = self._normalize_category(title)
        elif level == 3:  # Subcategories
            self.current_subcategory = title
        elif level == 4:  # Individual issues
            self._extract_issue_parameters(title, content)
    
    def _normalize_category(self, title: str) -> str:
        """Normalize category names."""
        categories = {
            'performance and scalability': 'performance',
            'system stability': 'stability', 
            'hardware support': 'hardware',
            'technical challenges': 'technical',
            'development areas': 'development',
            'implementation challenges': 'implementation',
            'performance bottlenecks': 'performance',
            'bug categories': 'bugs'
        }
        return categories.get(title.lower(), title.lower().replace(' ', '_'))
    
    def _extract_issue_parameters(self, title: str, content: str) -> None:
        """Extract test parameters from an individual issue."""
        # Extract structured information
        issue_match = re.search(r'-\s*\*\*Issue\*\*:\s*(.+)', content)
        impact_match = re.search(r'-\s*\*\*Impact\*\*:\s*(.+)', content)
        status_match = re.search(r'-\s*\*\*Status\*\*:\s*(.+)', content)
        challenge_match = re.search(r'-\s*\*\*Challenge\*\*:\s*(.+)', content)
        location_match = re.search(r'-\s*\*\*Location\*\*:\s*(.+)', content)
        
        # Extract solutions
        solutions = self._extract_solutions(content)
        
        # Build description
        description_parts = []
        if issue_match:
            description_parts.append(f"Issue: {issue_match.group(1).strip()}")
        if challenge_match:
            description_parts.append(f"Challenge: {challenge_match.group(1).strip()}")
        if location_match:
            description_parts.append(f"Location: {location_match.group(1).strip()}")
        
        description = '; '.join(description_parts) if description_parts else title
        
        # Determine impact area and failure mode
        impact_area = impact_match.group(1).strip() if impact_match else "System functionality"
        failure_mode = self._determine_failure_mode(title, content)
        
        # Extract resolution criteria from solutions
        resolution_criteria = self._extract_resolution_criteria(solutions, content)
        
        # Extract dependencies
        dependencies = self._extract_dependencies(content)
        
        # Create cognitive grammar hooks
        cognitive_hooks = self._create_cognitive_hooks(title, content)
        
        # Create ggml kernel shape hooks  
        ggml_hooks = self._create_ggml_hooks(title, content)
        
        test_param = TestParameter(
            issue_title=title,
            description=description,
            impact_area=impact_area,
            failure_mode=failure_mode,
            resolution_criteria=resolution_criteria,
            dependencies=dependencies,
            category=self.current_category,
            subcategory=self.current_subcategory,
            status=status_match.group(1).strip() if status_match else "Unknown",
            solutions=solutions,
            cognitive_grammar_hooks=cognitive_hooks,
            ggml_kernel_shapes=ggml_hooks
        )
        
        self.test_parameters.append(test_param)
    
    def _extract_solutions(self, content: str) -> List[str]:
        """Extract solutions from content."""
        solutions = []
        
        # Look for solutions section
        solutions_match = re.search(r'-\s*\*\*Solutions\*\*:\s*(.*?)(?=\n-|\nP|\n#|\n\n|\Z)', content, re.DOTALL)
        if solutions_match:
            solutions_text = solutions_match.group(1).strip()
            # Split on bullet points
            for line in solutions_text.split('\n'):
                line = line.strip()
                if line.startswith('-') or line.startswith('•'):
                    solutions.append(line.lstrip('- •').strip())
        
        # Also look for mitigation
        mitigation_match = re.search(r'-\s*\*\*Mitigation\*\*:\s*(.+)', content)
        if mitigation_match:
            solutions.append(mitigation_match.group(1).strip())
        
        return solutions
    
    def _determine_failure_mode(self, title: str, content: str) -> str:
        """Determine failure mode from title and content."""
        # Map common patterns to failure modes
        if any(word in title.lower() for word in ['performance', 'slow', 'overhead']):
            return "Performance degradation"
        elif any(word in title.lower() for word in ['crash', 'stability', 'hang']):
            return "System instability"
        elif any(word in title.lower() for word in ['memory', 'leak', 'allocation']):
            return "Resource exhaustion"
        elif any(word in title.lower() for word in ['support', 'driver', 'hardware']):
            return "Functionality unavailable"
        elif any(word in title.lower() for word in ['dependency', 'circular']):
            return "Build/runtime failure"
        else:
            return "Functional error"
    
    def _extract_resolution_criteria(self, solutions: List[str], content: str) -> List[str]:
        """Extract resolution criteria from solutions and content."""
        criteria = []
        
        # Convert solutions to testable criteria
        for solution in solutions:
            if 'optimization' in solution.lower():
                criteria.append("Performance metrics show improvement")
            elif 'implementation' in solution.lower():
                criteria.append("Feature implemented and functional")
            elif 'fix' in solution.lower():
                criteria.append("Issue no longer reproduces")
            elif 'support' in solution.lower():
                criteria.append("Functionality available and tested")
            else:
                criteria.append(f"Solution implemented: {solution}")
        
        # Add default criteria if none found
        if not criteria:
            criteria.append("Issue resolved and tested")
        
        return criteria
    
    def _extract_dependencies(self, content: str) -> List[str]:
        """Extract dependencies from content."""
        dependencies = []
        
        # Look for common dependency patterns
        dep_patterns = [
            r'GNU Mach',
            r'glibc',
            r'Linux driver',
            r'x86_64',
            r'SMP',
            r'IPC',
            r'server',
            r'kernel'
        ]
        
        for pattern in dep_patterns:
            if re.search(pattern, content, re.IGNORECASE):
                dependencies.append(pattern)
        
        return list(set(dependencies))  # Remove duplicates
    
    def _create_cognitive_hooks(self, title: str, content: str) -> Dict[str, Any]:
        """Create hooks for cognitive grammar integration."""
        return {
            "concept_nodes": [
                {"name": f"Issue_{title.replace(' ', '_')}", "type": "ConceptNode"},
                {"name": f"Category_{self.current_category}", "type": "ConceptNode"}
            ],
            "predicate_nodes": [
                {"name": "has_impact", "type": "PredicateNode"},
                {"name": "requires_solution", "type": "PredicateNode"}
            ],
            "inference_rules": [
                {
                    "rule": "if issue exists and solution implemented then issue resolved",
                    "confidence": 0.8
                }
            ],
            "attention_allocation": {
                "priority": self._calculate_priority(title, content),
                "focus_areas": [self.current_category, self.current_subcategory]
            }
        }
    
    def _create_ggml_hooks(self, title: str, content: str) -> Dict[str, Any]:
        """Create hooks for ggml kernel shapes integration.""" 
        return {
            "tensor_shapes": {
                "issue_embedding": [1, 384],  # Standard embedding dimension
                "category_embedding": [1, 128],
                "solution_embeddings": [len(self._extract_solutions(content)), 256]
            },
            "kernel_operations": [
                {
                    "op": "embed_issue",
                    "input_shape": [1, "variable"],
                    "output_shape": [1, 384]
                },
                {
                    "op": "classify_category", 
                    "input_shape": [1, 384],
                    "output_shape": [1, 8]  # Number of categories
                },
                {
                    "op": "rank_solutions",
                    "input_shape": ["variable", 256],
                    "output_shape": ["variable", 1]
                }
            ],
            "memory_layout": {
                "issue_cache": {"size": "1MB", "alignment": 64},
                "solution_cache": {"size": "512KB", "alignment": 32}
            }
        }
    
    def _calculate_priority(self, title: str, content: str) -> float:
        """Calculate attention priority for cognitive kernel."""
        priority = 0.5  # Base priority
        
        # Increase priority for critical issues
        if any(word in title.lower() for word in ['critical', 'crash', 'security']):
            priority += 0.3
        elif any(word in title.lower() for word in ['performance', 'stability']):
            priority += 0.2
        elif any(word in title.lower() for word in ['bug', 'issue', 'problem']):
            priority += 0.1
        
        return min(priority, 1.0)
    
    def generate_json_catalog(self) -> None:
        """Generate JSON format test catalog."""
        # Group by category
        catalog = {}
        for param in self.test_parameters:
            category = param.category
            if category not in catalog:
                catalog[category] = []
            catalog[category].append(asdict(param))
        
        # Add metadata
        output = {
            "metadata": {
                "generated_from": str(self.input_file),
                "total_issues": len(self.test_parameters),
                "categories": list(catalog.keys()),
                "version": "1.0.0",
                "description": "Comprehensive test catalog extracted from open issues documentation"
            },
            "test_catalog": catalog
        }
        
        output_file = self.output_dir / "test-catalog.json"
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(output, f, indent=2, ensure_ascii=False)
        
        print(f"Generated JSON catalog: {output_file}")
    
    def generate_scheme_catalog(self) -> None:
        """Generate Scheme format test catalog."""
        output_file = self.output_dir / "test-catalog.scm"
        
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(";; Test Catalog for GNU Hurd Issues\n")
            f.write(";; Generated from open-issues.md\n")
            f.write(";; Integrates with cognitive kernel and ggml shapes\n\n")
            
            f.write("(define-module (test-catalog)\n")
            f.write("  #:use-module (cogkernel core)\n")
            f.write("  #:use-module (cogkernel atomspace)\n")
            f.write("  #:export (test-catalog\n")
            f.write("            get-test-parameters\n")
            f.write("            cognitive-test-hooks\n")
            f.write("            ggml-kernel-shapes))\n\n")
            
            # Generate test catalog data structure
            f.write("(define test-catalog\n")
            f.write("  '(\n")
            
            # Group by category
            catalog = {}
            for param in self.test_parameters:
                category = param.category
                if category not in catalog:
                    catalog[category] = []
                catalog[category].append(param)
            
            for category, params in catalog.items():
                f.write(f"    ({category}\n")
                for param in params:
                    f.write(f"     ((title . \"{self._escape_scheme_string(param.issue_title)}\")\n")
                    f.write(f"      (description . \"{self._escape_scheme_string(param.description)}\")\n")
                    f.write(f"      (impact-area . \"{self._escape_scheme_string(param.impact_area)}\")\n")
                    f.write(f"      (failure-mode . \"{self._escape_scheme_string(param.failure_mode)}\")\n")
                    f.write(f"      (subcategory . \"{self._escape_scheme_string(param.subcategory)}\")\n")
                    f.write(f"      (status . \"{self._escape_scheme_string(param.status)}\")\n")
                    f.write(f"      (resolution-criteria . {self._list_to_scheme(param.resolution_criteria)})\n")
                    f.write(f"      (dependencies . {self._list_to_scheme(param.dependencies)})\n")
                    f.write(f"      (solutions . {self._list_to_scheme(param.solutions)}))\n")
                f.write("     )\n")
            
            f.write("    ))\n\n")
            
            # Add helper functions
            f.write("(define (get-test-parameters category)\n")
            f.write("  \"Get test parameters for a specific category\"\n")
            f.write("  (assoc-ref test-catalog category))\n\n")
            
            # Add cognitive integration hooks
            f.write("(define cognitive-test-hooks\n")
            f.write("  \"Hooks for cognitive kernel integration\"\n")
            f.write("  '((concept-extraction . extract-issue-concepts)\n")
            f.write("    (attention-allocation . allocate-test-attention)\n")
            f.write("    (inference-rules . test-inference-rules)\n")
            f.write("    (learning-feedback . test-result-feedback)))\n\n")
            
            # Add ggml integration hooks
            f.write("(define ggml-kernel-shapes\n")
            f.write("  \"GGML kernel shape specifications for test processing\"\n")
            f.write("  '((issue-embedding-shape . (1 384))\n")
            f.write("    (category-classification-shape . (1 8))\n")
            f.write("    (solution-ranking-shape . (variable 256))\n")
            f.write("    (memory-layout . ((issue-cache . 1048576)\n")
            f.write("                      (solution-cache . 524288)))))\n")
        
        print(f"Generated Scheme catalog: {output_file}")
    
    def _escape_scheme_string(self, s: str) -> str:
        """Escape string for Scheme output."""
        return s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n')
    
    def _list_to_scheme(self, lst: List[str]) -> str:
        """Convert Python list to Scheme list format."""
        if not lst:
            return "'()"
        escaped = [f'"{self._escape_scheme_string(item)}"' for item in lst]
        return f"'({' '.join(escaped)})"
    
    def generate_catalogs(self) -> None:
        """Generate both JSON and Scheme catalogs."""
        self.parse_markdown()
        
        # Ensure output directory exists
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        self.generate_json_catalog()
        self.generate_scheme_catalog()
        
        print(f"\nGenerated test catalog with {len(self.test_parameters)} test parameters")
        print(f"Categories: {', '.join(set(p.category for p in self.test_parameters))}")


def main():
    """Main entry point."""
    if len(sys.argv) > 1:
        input_file = sys.argv[1]
    else:
        # Default to the expected location
        input_file = "/home/runner/work/9nu/9nu/docs/open-issues/open-issues.md"
    
    if len(sys.argv) > 2:
        output_dir = sys.argv[2]
    else:
        # Default to same directory as input
        output_dir = os.path.dirname(input_file)
    
    if not os.path.exists(input_file):
        print(f"Error: Input file {input_file} not found")
        sys.exit(1)
    
    generator = TestCatalogGenerator(input_file, output_dir)
    generator.generate_catalogs()


if __name__ == "__main__":
    main()