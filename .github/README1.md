# Hurd GitHub Actions

This directory contains GitHub Actions for the Hurd project to automate issue generation and roadmap creation.

## Available Actions

### 1. Generate Open Issues from Documentation

**File:** `.github/workflows/generate-open-issues.yml`

This action parses the open issues documentation structure and generates GitHub issues for each item with actionable steps.

#### Features:
- Automatically creates issues for each documentation item
- Generates actionable steps based on item type and level
- Maintains hierarchical structure with parent-child relationships
- Adds appropriate labels and metadata
- Can be run manually or on a schedule

#### Usage:

**Manual Run:**
1. Go to the Actions tab in the GitHub repository
2. Select "Generate Open Issues from Documentation"
3. Click "Run workflow"
4. Optionally enable "Dry run" to preview without creating issues

**Scheduled Run:**
- The action runs automatically every Monday at 9 AM UTC
- Issues are created with appropriate labels and actionable steps

#### Configuration:

The action uses the following environment variables:
- `GITHUB_TOKEN`: GitHub token for API access (automatically provided)
- `GITHUB_REPOSITORY_OWNER`: Repository owner (defaults to 'gnu')
- `GITHUB_REPOSITORY`: Repository name (defaults to 'gnu/hurd')

#### Output:

The action generates:
- GitHub issues for each documentation item
- A JSON file (`open_issues_structure.json`) with the parsed structure
- Actionable steps for each issue based on its category and level

### 2. Development Roadmap Generation

**File:** `.github/scripts/create_roadmap.py`

This script generates an advanced development roadmap with Mermaid and PlantUML diagrams.

#### Features:
- Comprehensive component status tracking
- Visual architecture diagrams
- Development timeline and phases
- Priority matrix and risk assessment
- Success metrics for each phase

#### Generated Content:

1. **Mermaid Diagrams:**
   - System architecture overview
   - Development status pie chart
   - Component dependencies

2. **PlantUML Diagrams:**
   - Detailed system architecture
   - Development roadmap timeline

3. **Markdown Tables:**
   - Component status table
   - Priority matrix
   - Success criteria

#### Output:

The script generates `DEVELOPMENT_ROADMAP.md` containing:
- Architecture overview with diagrams
- Development phases and timelines
- Component status and priorities
- Success metrics and risk assessment
- Contributing guidelines

## Scripts

### generate_issues.py

**Location:** `.github/scripts/generate_issues.py`

Parses the open issues documentation structure and creates GitHub issues.

**Key Functions:**
- `parse_documentation_structure()`: Parses the nested documentation structure
- `generate_actionable_steps()`: Creates actionable steps for each issue
- `create_github_issue()`: Creates GitHub issues via API
- `run()`: Main execution method

**Usage:**
```bash
python .github/scripts/generate_issues.py
```

### create_roadmap.py

**Location:** `.github/scripts/create_roadmap.py`

Generates comprehensive development roadmap with diagrams.

**Key Functions:**
- `generate_mermaid_architecture_diagram()`: Creates Mermaid architecture diagram
- `generate_plantuml_architecture()`: Creates PlantUML architecture diagram
- `generate_component_status_table()`: Creates status table
- `generate_roadmap_markdown()`: Generates complete roadmap document

**Usage:**
```bash
python .github/scripts/create_roadmap.py
```

## Component Status

The roadmap tracks components in the following categories:

### Status Types:
- ✅ **Complete**: Fully implemented and functional
- 🔄 **In Progress**: Currently being developed
- 📋 **Planned**: Scheduled for development
- ❌ **Missing**: Not yet implemented

### Priority Levels:
- 🔴 **High**: Critical for system functionality
- 🟡 **Medium**: Important but not critical
- 🟢 **Low**: Nice to have features

### Categories:
- **Microkernel**: Core kernel components
- **Servers**: Hurd server implementations
- **Translators**: File system translators
- **Libraries**: Support libraries
- **Utilities**: System utilities
- **Tools**: Development tools
- **Boot**: Boot system components

## Development Phases

### Phase 1: Core Stability (2024 Q1-Q2)
Focus on completing core system components and improving stability.

### Phase 2: Missing Components (2024 Q2-Q3)
Implement missing core system components like sound and graphics servers.

### Phase 3: Advanced Features (2024 Q3-Q4)
Add advanced system features and capabilities.

### Phase 4: Polish & Documentation (2024 Q4-2025 Q1)
System polish, comprehensive testing, and documentation.

## Contributing

To contribute to the automation:

1. **Modify Issue Generation:**
   - Edit `generate_issues.py` to change issue creation logic
   - Update the documentation structure in the script
   - Modify actionable steps generation

2. **Update Roadmap:**
   - Edit `create_roadmap.py` to update component status
   - Modify diagrams and visualizations
   - Update development phases and timelines

3. **Add New Actions:**
   - Create new workflow files in `.github/workflows/`
   - Add corresponding scripts in `.github/scripts/`
   - Update this README with documentation

## Dependencies

The scripts require the following Python packages:
- `requests`: For GitHub API calls
- `pyyaml`: For YAML processing
- `dataclasses`: For data structures (Python 3.7+)

## Troubleshooting

### Common Issues:

1. **GitHub API Rate Limits:**
   - The action respects GitHub's rate limits
   - Issues are created with delays if needed

2. **Permission Issues:**
   - Ensure the workflow has `issues: write` permission
   - Check that the GitHub token is valid

3. **Script Errors:**
   - Check Python version (requires 3.7+)
   - Verify all dependencies are installed
   - Review error logs in the Actions tab

### Debugging:

1. **Dry Run Mode:**
   - Use the "Dry run" option to preview without creating issues
   - Check the generated JSON structure

2. **Manual Testing:**
   - Run scripts locally to test functionality
   - Use `python -m pytest` if tests are added

## License

This automation is part of the Hurd project and follows the same licensing terms.

## Support

For issues with the automation:
1. Check the Actions tab for error logs
2. Review the generated files for correctness
3. Open an issue in the repository with details
4. Contact the Hurd development team

---

*Last updated: Generated automatically by the GitHub Action*
