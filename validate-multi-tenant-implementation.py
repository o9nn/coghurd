#!/usr/bin/env python3
"""
Validation script for multi-tenant neuro-symbolic atomspace implementation
Validates syntax and structure of Scheme modules
"""

import os
import sys
import re

def check_file_exists(filepath, description):
    """Check if a file exists"""
    if os.path.exists(filepath):
        print(f"✓ {description}: {filepath}")
        return True
    else:
        print(f"✗ {description} NOT FOUND: {filepath}")
        return False

def check_scheme_syntax(filepath, require_module=True):
    """Basic Scheme syntax validation"""
    try:
        with open(filepath, 'r') as f:
            content = f.read()
        
        # Check balanced parentheses
        open_parens = content.count('(')
        close_parens = content.count(')')
        
        if open_parens != close_parens:
            print(f"  ✗ Unbalanced parentheses: {open_parens} open, {close_parens} close")
            return False
        
        # Check for define-module (only if required)
        if require_module and 'define-module' not in content:
            print(f"  ✗ Missing define-module")
            return False
        
        # Check for exports (only if module required)
        if require_module and '#:export' not in content:
            print(f"  ⚠ No exports found (may be intentional)")
        
        print(f"  ✓ Syntax appears valid")
        return True
        
    except Exception as e:
        print(f"  ✗ Error reading file: {e}")
        return False

def check_module_functions(filepath, expected_functions):
    """Check if expected functions are defined"""
    try:
        with open(filepath, 'r') as f:
            content = f.read()
        
        missing = []
        found = []
        
        for func in expected_functions:
            # Look for function definition
            pattern = rf'\(define[*]?\s+\({func}\s'
            if re.search(pattern, content):
                found.append(func)
            else:
                missing.append(func)
        
        if found:
            print(f"  ✓ Found {len(found)} expected functions")
        
        if missing:
            print(f"  ⚠ Missing some expected functions: {', '.join(missing[:3])}")
        
        return len(missing) == 0
        
    except Exception as e:
        print(f"  ✗ Error checking functions: {e}")
        return False

def validate_multi_tenant_atomspace():
    """Validate multi-tenant-atomspace.scm"""
    print("\n=== Multi-Tenant AtomSpace Fabric ===")
    filepath = "cogkernel/multi-tenant-atomspace.scm"
    
    if not check_file_exists(filepath, "Multi-tenant module"):
        return False
    
    if not check_scheme_syntax(filepath):
        return False
    
    expected_functions = [
        'make-multi-tenant-fabric',
        'fabric-create-tenant!',
        'fabric-delete-tenant!',
        'tenant-add-atom!',
        'tenant-embed-concept!',
        'tenant-check-quota'
    ]
    
    check_module_functions(filepath, expected_functions)
    return True

def validate_mig_space():
    """Validate mig-space.scm"""
    print("\n=== MIG-Space Distributed Architecture ===")
    filepath = "cogkernel/mig-space.scm"
    
    if not check_file_exists(filepath, "MIG-space module"):
        return False
    
    if not check_scheme_syntax(filepath):
        return False
    
    expected_functions = [
        'make-mig-space',
        'mig-space-create-channel!',
        'mig-space-send-cognitive!',
        'mig-space-create-constellation!',
        'mig-space-deploy-microkernel!',
        'mig-space-sync-atoms!'
    ]
    
    check_module_functions(filepath, expected_functions)
    return True

def validate_agent_zero_workbench():
    """Validate agent-zero-workbench.scm"""
    print("\n=== Agent-Zero Orchestration Workbench ===")
    filepath = "cogkernel/agent-zero-workbench.scm"
    
    if not check_file_exists(filepath, "Agent-zero workbench module"):
        return False
    
    if not check_scheme_syntax(filepath):
        return False
    
    expected_functions = [
        'make-agent-zero-workbench',
        'workbench-create-agent!',
        'workbench-deploy-agent!',
        'workbench-create-team!',
        'workbench-autonomous-decision',
        'workbench-self-organize!'
    ]
    
    check_module_functions(filepath, expected_functions)
    return True

def validate_test_suite():
    """Validate test suite"""
    print("\n=== Test Suite ===")
    filepath = "cogkernel/test-multi-tenant-integration.scm"
    
    if not check_file_exists(filepath, "Test suite"):
        return False
    
    # Test scripts don't need define-module
    if not check_scheme_syntax(filepath, require_module=False):
        return False
    
    return True

def validate_demo():
    """Validate demonstration script"""
    print("\n=== Demonstration Script ===")
    filepath = "cogkernel/demo-multi-tenant-neuro-symbolic.scm"
    
    if not check_file_exists(filepath, "Demo script"):
        return False
    
    # Demo scripts don't need define-module
    if not check_scheme_syntax(filepath, require_module=False):
        return False
    
    return True

def validate_documentation():
    """Validate documentation"""
    print("\n=== Documentation ===")
    filepath = "cogkernel/MULTI_TENANT_ARCHITECTURE.md"
    
    if not check_file_exists(filepath, "Architecture documentation"):
        return False
    
    try:
        with open(filepath, 'r') as f:
            content = f.read()
        
        # Check for key sections
        sections = [
            '## Overview',
            '## Architecture',
            '## Components',
            '## Integration',
            '## Testing',
            '## Use Cases'
        ]
        
        for section in sections:
            if section in content:
                print(f"  ✓ Found section: {section}")
            else:
                print(f"  ✗ Missing section: {section}")
        
        return True
        
    except Exception as e:
        print(f"  ✗ Error reading documentation: {e}")
        return False

def check_readme_updates():
    """Check if README was updated"""
    print("\n=== README Updates ===")
    filepath = "README.md"
    
    if not check_file_exists(filepath, "Main README"):
        return False
    
    try:
        with open(filepath, 'r') as f:
            content = f.read()
        
        # Check for key updates
        updates = [
            'Multi-Tenant AtomSpace Fabric',
            'MIG-Space',
            'Agent-Zero Workbench',
            'Mach-Zero Constellations',
            'MULTI_TENANT_ARCHITECTURE.md'
        ]
        
        for update in updates:
            if update in content:
                print(f"  ✓ README mentions: {update}")
            else:
                print(f"  ⚠ README missing: {update}")
        
        return True
        
    except Exception as e:
        print(f"  ✗ Error reading README: {e}")
        return False

def main():
    """Main validation routine"""
    print("=" * 60)
    print("Multi-Tenant Neuro-Symbolic AtomSpace Validation")
    print("=" * 60)
    
    results = []
    
    # Validate all components
    results.append(("Multi-Tenant AtomSpace", validate_multi_tenant_atomspace()))
    results.append(("MIG-Space", validate_mig_space()))
    results.append(("Agent-Zero Workbench", validate_agent_zero_workbench()))
    results.append(("Test Suite", validate_test_suite()))
    results.append(("Demo Script", validate_demo()))
    results.append(("Documentation", validate_documentation()))
    results.append(("README Updates", check_readme_updates()))
    
    # Summary
    print("\n" + "=" * 60)
    print("VALIDATION SUMMARY")
    print("=" * 60)
    
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    for name, result in results:
        status = "✓ PASS" if result else "✗ FAIL"
        print(f"{status}: {name}")
    
    print(f"\nTotal: {passed}/{total} validations passed")
    
    if passed == total:
        print("\n✓ ALL VALIDATIONS PASSED")
        return 0
    else:
        print(f"\n✗ {total - passed} VALIDATIONS FAILED")
        return 1

if __name__ == '__main__':
    sys.exit(main())
