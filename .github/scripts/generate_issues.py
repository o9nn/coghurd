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
from urllib.parse import urlparse

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
    def __init__(self, github_token: Optional[str] = None):
        self.github_token = github_token or os.getenv('GITHUB_TOKEN')
        self.repo_owner = os.getenv('GITHUB_REPOSITORY_OWNER', 'gnu')
        self.repo_name = os.getenv('GITHUB_REPOSITORY', 'gnu/hurd')
        self.api_base = f"https://api.github.com/repos/{self.repo_owner}/{self.repo_name}"
        
    def parse_documentation_structure(self) -> List[IssueItem]:
        """Parse the open issues documentation structure."""
        
        # This is the structure from the provided documentation
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
                        "level": 1,
                        "children": {
                            "2013": {
                                "url": "https://www.gnu.org/software/hurd/community/gsoc/2013.html",
                                "level": 2,
                                "children": {
                                    "hacklu": {
                                        "url": "https://www.gnu.org/software/hurd/community/gsoc/2013/hacklu.html",
                                        "level": 3
                                    }
                                }
                            },
                            "project_ideas": {
                                "url": "https://www.gnu.org/software/hurd/community/gsoc/project_ideas.html",
                                "level": 2,
                                "children": {
                                    "server_overriding": {
                                        "url": "https://www.gnu.org/software/hurd/community/gsoc/project_ideas/server_overriding.html",
                                        "level": 3,
                                        "children": {
                                            "sound_discussion": {
                                                "url": "https://www.gnu.org/software/hurd/community/gsoc/project_ideas/sound/discussion.html",
                                                "level": 4
                                            },
                                            "testing_framework_discussion": {
                                                "url": "https://www.gnu.org/software/hurd/community/gsoc/project_ideas/testing_framework/discussion.html",
                                                "level": 4
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    },
                    "weblogs": {
                        "url": "https://www.gnu.org/software/hurd/community/weblogs.html",
                        "level": 1,
                        "children": {
                            "ArneBab": {
                                "url": "https://www.gnu.org/software/hurd/community/weblogs/ArneBab.html",
                                "level": 2,
                                "children": {
                                    "technical_advantages": {
                                        "url": "https://www.gnu.org/software/hurd/community/weblogs/ArneBab/technical-advantages-of-the-hurd.html",
                                        "level": 3,
                                        "children": {
                                            "discussion": {
                                                "url": "https://www.gnu.org/software/hurd/community/weblogs/ArneBab/technical-advantages-of-the-hurd/discussion.html",
                                                "level": 4
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            },
            "contributing": {
                "url": "https://www.gnu.org/software/hurd/contributing.html",
                "level": 0,
                "children": {
                    "discussion": {
                        "url": "https://www.gnu.org/software/hurd/contributing/discussion.html",
                        "level": 1
                    }
                }
            },
            "documentation": {"url": "https://www.gnu.org/software/hurd/documentation.html", "level": 0},
            "faq": {
                "url": "https://www.gnu.org/software/hurd/faq.html",
                "level": 0,
                "children": {
                    "binary_compatibility": {
                        "url": "https://www.gnu.org/software/hurd/faq/binary_compatibility.html",
                        "level": 1
                    },
                    "network_transparency": {
                        "url": "https://www.gnu.org/software/hurd/faq/network_transparency.html",
                        "level": 1,
                        "children": {
                            "posix_compatibility_discussion": {
                                "url": "https://www.gnu.org/software/hurd/faq/posix_compatibility/discussion.html",
                                "level": 2
                            },
                            "slash_usr_symlink_discussion": {
                                "url": "https://www.gnu.org/software/hurd/faq/slash_usr_symlink/discussion.html",
                                "level": 2
                            },
                            "which_microkernel_discussion": {
                                "url": "https://www.gnu.org/software/hurd/faq/which_microkernel/discussion.html",
                                "level": 2
                            }
                        }
                    }
                }
            },
            "glibc": {
                "url": "https://www.gnu.org/software/hurd/glibc.html",
                "level": 0,
                "children": {
                    "discussion": {
                        "url": "https://www.gnu.org/software/hurd/glibc/discussion.html",
                        "level": 1
                    },
                    "file_descriptor": {
                        "url": "https://www.gnu.org/software/hurd/glibc/file_descriptor.html",
                        "level": 1
                    },
                    "fork": {
                        "url": "https://www.gnu.org/software/hurd/glibc/fork.html",
                        "level": 1
                    },
                    "ioctl": {
                        "url": "https://www.gnu.org/software/hurd/glibc/ioctl.html",
                        "level": 1
                    },
                    "select": {
                        "url": "https://www.gnu.org/software/hurd/glibc/select.html",
                        "level": 1,
                        "children": {
                            "signal_thread": {
                                "url": "https://www.gnu.org/software/hurd/glibc/signal/signal_thread.html",
                                "level": 2
                            }
                        }
                    },
                    "startup": {
                        "url": "https://www.gnu.org/software/hurd/glibc/startup.html",
                        "level": 1
                    }
                }
            },
            "hurd": {
                "url": "https://www.gnu.org/software/hurd/hurd.html",
                "level": 0,
                "children": {
                    "coding_style": {
                        "url": "https://www.gnu.org/software/hurd/hurd/coding_style.html",
                        "level": 1
                    },
                    "console": {
                        "url": "https://www.gnu.org/software/hurd/hurd/console.html",
                        "level": 1,
                        "children": {
                            "discussion": {
                                "url": "https://www.gnu.org/software/hurd/hurd/console/discussion.html",
                                "level": 2
                            },
                            "dde_guide_discussion": {
                                "url": "https://www.gnu.org/software/hurd/hurd/dde/guide/discussion.html",
                                "level": 2
                            },
                            "rpctrace": {
                                "url": "https://www.gnu.org/software/hurd/hurd/debugging/rpctrace.html",
                                "level": 2
                            },
                            "trap_in_kernel": {
                                "url": "https://www.gnu.org/software/hurd/hurd/debugging/trap_in_the_kernel.html",
                                "level": 2
                            }
                        }
                    },
                    "io_path": {
                        "url": "https://www.gnu.org/software/hurd/hurd/io_path.html",
                        "level": 1
                    },
                    "libps": {
                        "url": "https://www.gnu.org/software/hurd/hurd/libps.html",
                        "level": 1
                    },
                    "libstore": {
                        "url": "https://www.gnu.org/software/hurd/hurd/libstore.html",
                        "level": 1,
                        "children": {
                            "part_store": {
                                "url": "https://www.gnu.org/software/hurd/hurd/libstore/part.html",
                                "level": 2,
                                "children": {
                                    "qemu_discussion": {
                                        "url": "https://www.gnu.org/software/hurd/hurd/running/qemu/discussion.html",
                                        "level": 3
                                    },
                                    "writeback_caching": {
                                        "url": "https://www.gnu.org/software/hurd/hurd/running/qemu/writeback_caching.html",
                                        "level": 3
                                    }
                                }
                            },
                            "settrans_discussion": {
                                "url": "https://www.gnu.org/software/hurd/hurd/settrans/discussion.html",
                                "level": 2
                            },
                            "subhurd_discussion": {
                                "url": "https://www.gnu.org/software/hurd/hurd/subhurd/discussion.html",
                                "level": 2
                            },
                            "auth": {
                                "url": "https://www.gnu.org/software/hurd/hurd/translator/auth.html",
                                "level": 2
                            },
                            "devfs": {
                                "url": "https://www.gnu.org/software/hurd/hurd/translator/devfs.html",
                                "level": 2
                            },
                            "translator_discussion": {
                                "url": "https://www.gnu.org/software/hurd/hurd/translator/discussion.html",
                                "level": 2
                            },
                            "ext2fs_hurd_extensions": {
                                "url": "https://www.gnu.org/software/hurd/hurd/translator/ext2fs/hurd-specific_extensions.html",
                                "level": 2
                            },
                            "ext2fs_internal_allocator": {
                                "url": "https://www.gnu.org/software/hurd/hurd/translator/ext2fs/internal_allocator.html",
                                "level": 2
                            },
                            "ext2fs_page_cache": {
                                "url": "https://www.gnu.org/software/hurd/hurd/translator/ext2fs/page_cache.html",
                                "level": 2
                            },
                            "firmlink": {
                                "url": "https://www.gnu.org/software/hurd/hurd/translator/firmlink.html",
                                "level": 2
                            },
                            "httpfs": {
                                "url": "https://www.gnu.org/software/hurd/hurd/translator/httpfs.html",
                                "level": 2,
                                "children": {
                                    "mtab_discussion": {
                                        "url": "https://www.gnu.org/software/hurd/hurd/translator/mtab/discussion.html",
                                        "level": 3
                                    },
                                    "procfs_jkoenig_discussion": {
                                        "url": "https://www.gnu.org/software/hurd/hurd/translator/procfs/jkoenig/discussion.html",
                                        "level": 3
                                    }
                                }
                            },
                            "virtual_file_system_discussion": {
                                "url": "https://www.gnu.org/software/hurd/hurd/virtual_file_system/discussion.html",
                                "level": 2
                            }
                        }
                    }
                }
            },
            "microkernel": {
                "url": "https://www.gnu.org/software/hurd/microkernel.html",
                "level": 0,
                "children": {
                    "discussion": {
                        "url": "https://www.gnu.org/software/hurd/microkernel/discussion.html",
                        "level": 1
                    },
                    "eros": {
                        "url": "https://www.gnu.org/software/hurd/microkernel/eros.html",
                        "level": 1
                    },
                    "mach": {
                        "url": "https://www.gnu.org/software/hurd/microkernel/mach.html",
                        "level": 1,
                        "children": {
                            "deficiencies": {
                                "url": "https://www.gnu.org/software/hurd/microkernel/mach/deficiencies.html",
                                "level": 2
                            },
                            "external_pager_mechanism": {
                                "url": "https://www.gnu.org/software/hurd/microkernel/mach/external_pager_mechanism.html",
                                "level": 2
                            },
                            "gnumach": {
                                "url": "https://www.gnu.org/software/hurd/microkernel/mach/gnumach.html",
                                "level": 2,
                                "children": {
                                    "hardware_compatibility_list": {
                                        "url": "https://www.gnu.org/software/hurd/microkernel/mach/gnumach/hardware_compatibility_list.html",
                                        "level": 3,
                                        "children": {
                                            "discussion": {
                                                "url": "https://www.gnu.org/software/hurd/microkernel/mach/gnumach/hardware_compatibility_list/discussion.html",
                                                "level": 4
                                            }
                                        }
                                    },
                                    "interface": {
                                        "url": "https://www.gnu.org/software/hurd/microkernel/mach/gnumach/interface.html",
                                        "level": 3,
                                        "children": {
                                            "task_set_name": {
                                                "url": "https://www.gnu.org/software/hurd/microkernel/mach/gnumach/interface/task_set_name.html",
                                                "level": 4
                                            },
                                            "thread_get_set_state": {
                                                "url": "https://www.gnu.org/software/hurd/microkernel/mach/gnumach/interface/thread_get_state.html",
                                                "level": 4
                                            }
                                        }
                                    },
                                    "memory_management": {
                                        "url": "https://www.gnu.org/software/hurd/microkernel/mach/gnumach/memory_management.html",
                                        "level": 3
                                    },
                                    "ports": {
                                        "url": "https://www.gnu.org/software/hurd/microkernel/mach/gnumach/ports.html",
                                        "level": 3,
                                        "children": {
                                            "xen": {
                                                "url": "https://www.gnu.org/software/hurd/microkernel/mach/gnumach/ports/xen.html",
                                                "level": 4,
                                                "children": {
                                                    "discussion": {
                                                        "url": "https://www.gnu.org/software/hurd/microkernel/mach/gnumach/ports/xen/discussion.html",
                                                        "level": 5
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            },
                            "history": {
                                "url": "https://www.gnu.org/software/hurd/microkernel/mach/history.html",
                                "level": 2
                            },
                            "memory_object": {
                                "url": "https://www.gnu.org/software/hurd/microkernel/mach/memory_object.html",
                                "level": 2,
                                "children": {
                                    "discussion": {
                                        "url": "https://www.gnu.org/software/hurd/microkernel/mach/memory_object/discussion.html",
                                        "level": 3
                                    }
                                }
                            },
                            "mig": {
                                "url": "https://www.gnu.org/software/hurd/microkernel/mach/mig.html",
                                "level": 2,
                                "children": {
                                    "documentation": {
                                        "url": "https://www.gnu.org/software/hurd/microkernel/mach/mig/documentation.html",
                                        "level": 3
                                    }
                                }
                            },
                            "pmap": {
                                "url": "https://www.gnu.org/software/hurd/microkernel/mach/pmap.html",
                                "level": 2
                            },
                            "rpc": {
                                "url": "https://www.gnu.org/software/hurd/microkernel/mach/rpc.html",
                                "level": 2,
                                "children": {
                                    "discussion": {
                                        "url": "https://www.gnu.org/software/hurd/microkernel/mach/rpc/discussion.html",
                                        "level": 3
                                    }
                                }
                            },
                            "thread": {
                                "url": "https://www.gnu.org/software/hurd/microkernel/mach/thread.html",
                                "level": 2
                            }
                        }
                    },
                    "viengoos": {
                        "url": "https://www.gnu.org/software/hurd/microkernel/viengoos.html",
                        "level": 1,
                        "children": {
                            "documentation": {
                                "url": "https://www.gnu.org/software/hurd/microkernel/viengoos/documentation.html",
                                "level": 2,
                                "children": {
                                    "irc_2012_02_23": {
                                        "url": "https://www.gnu.org/software/hurd/microkernel/viengoos/documentation/irc_2012-02-23.html",
                                        "level": 3
                                    }
                                }
                            }
                        }
                    }
                }
            },
            "naming_context": {"url": "https://www.gnu.org/software/hurd/naming_context.html", "level": 0},
            "open_issues": {
                "url": "https://www.gnu.org/software/hurd/open_issues.html",
                "level": 0,
                "children": {
                    "active_vs_passive_symlink_translator": {
                        "url": "https://www.gnu.org/software/hurd/open_issues/active_vs_passive_symlink_translator.html",
                        "level": 1
                    },
                    "anatomy_of_a_hurd_system": {
                        "url": "https://www.gnu.org/software/hurd/open_issues/anatomy_of_a_hurd_system.html",
                        "level": 1
                    },
                    "benefits_of_a_native_hurd_implementation": {
                        "url": "https://www.gnu.org/software/hurd/open_issues/benefits_of_a_native_hurd_implementation.html",
                        "level": 1
                    },
                    "bsd_compatibility": {
                        "url": "https://www.gnu.org/software/hurd/open_issues/bsd_compatibility.html",
                        "level": 1,
                        "children": {
                            "code_analysis_discussion": {
                                "url": "https://www.gnu.org/software/hurd/open_issues/code_analysis/discussion.html",
                                "level": 2
                            }
                        }
                    },
                    "contributing": {
                        "url": "https://www.gnu.org/software/hurd/open_issues/contributing.html",
                        "level": 1
                    },
                    "ext2fs_page_cache_swapping_leak": {
                        "url": "https://www.gnu.org/software/hurd/open_issues/ext2fs_page_cache_swapping_leak.html",
                        "level": 1,
                        "children": {
                            "glibc_tls": {
                                "url": "https://www.gnu.org/software/hurd/open_issues/glibc/t/tls.html",
                                "level": 2
                            }
                        }
                    },
                    "hurd_101": {
                        "url": "https://www.gnu.org/software/hurd/open_issues/hurd_101.html",
                        "level": 1
                    },
                    "implementing_hurd_on_top_of_another_system": {
                        "url": "https://www.gnu.org/software/hurd/open_issues/implementing_hurd_on_top_of_another_system.html",
                        "level": 1
                    },
                    "mach_federations": {
                        "url": "https://www.gnu.org/software/hurd/open_issues/mach_federations.html",
                        "level": 1
                    },
                    "mach_migrating_threads": {
                        "url": "https://www.gnu.org/software/hurd/open_issues/mach_migrating_threads.html",
                        "level": 1
                    },
                    "mach_tasks_memory_usage": {
                        "url": "https://www.gnu.org/software/hurd/open_issues/mach_tasks_memory_usage.html",
                        "level": 1
                    },
                    "memory_object_model_vs_block_level_cache": {
                        "url": "https://www.gnu.org/software/hurd/open_issues/memory_object_model_vs_block-level_cache.html",
                        "level": 1
                    },
                    "mission_statement": {
                        "url": "https://www.gnu.org/software/hurd/open_issues/mission_statement.html",
                        "level": 1
                    },
                    "mmap_crash_etc": {
                        "url": "https://www.gnu.org/software/hurd/open_issues/mmap_crash_etc.html",
                        "level": 1
                    },
                    "multiprocessing": {
                        "url": "https://www.gnu.org/software/hurd/open_issues/multiprocessing.html",
                        "level": 1
                    },
                    "neals_hurd_misc_papers": {
                        "url": "https://www.gnu.org/software/hurd/open_issues/neals_hurd-misc_papers.html",
                        "level": 1
                    },
                    "notmuch_n_gmane": {
                        "url": "https://www.gnu.org/software/hurd/open_issues/notmuch_n_gmane.html",
                        "level": 1
                    },
                    "performance": {
                        "url": "https://www.gnu.org/software/hurd/open_issues/performance.html",
                        "level": 1,
                        "children": {
                            "ipc_virtual_copy": {
                                "url": "https://www.gnu.org/software/hurd/open_issues/performance/ipc_virtual_copy.html",
                                "level": 2
                            },
                            "microkernel_multi_server": {
                                "url": "https://www.gnu.org/software/hurd/open_issues/performance/microkernel_multi-server.html",
                                "level": 2
                            }
                        }
                    },
                    "resource_management_problems": {
                        "url": "https://www.gnu.org/software/hurd/open_issues/resource_management_problems.html",
                        "level": 1
                    },
                    "robustness": {
                        "url": "https://www.gnu.org/software/hurd/open_issues/robustness.html",
                        "level": 1
                    },
                    "serial_console": {
                        "url": "https://www.gnu.org/software/hurd/open_issues/serial_console.html",
                        "level": 1
                    },
                    "system_stats": {
                        "url": "https://www.gnu.org/software/hurd/open_issues/system_stats.html",
                        "level": 1
                    },
                    "translator_stdout_stderr": {
                        "url": "https://www.gnu.org/software/hurd/open_issues/translator_stdout_stderr.html",
                        "level": 1
                    },
                    "user_space_device_drivers": {
                        "url": "https://www.gnu.org/software/hurd/open_issues/user-space_device_drivers.html",
                        "level": 1
                    },
                    "virtualization": {
                        "url": "https://www.gnu.org/software/hurd/open_issues/virtualization.html",
                        "level": 1,
                        "children": {
                            "remap_root_translator": {
                                "url": "https://www.gnu.org/software/hurd/open_issues/virtualization/remap_root_translator.html",
                                "level": 2
                            }
                        }
                    }
                }
            },
            "persistency": {"url": "https://www.gnu.org/software/hurd/persistency.html", "level": 0},
            "source_repositories": {
                "url": "https://www.gnu.org/software/hurd/source_repositories.html",
                "level": 0,
                "children": {
                    "discussion": {
                        "url": "https://www.gnu.org/software/hurd/source_repositories/discussion.html",
                        "level": 1
                    }
                }
            },
            "unix": {"url": "https://www.gnu.org/software/hurd/unix.html", "level": 0},
            "user": {
                "url": "https://www.gnu.org/software/hurd/user.html",
                "level": 0,
                "children": {
                    "jkoenig": {
                        "url": "https://www.gnu.org/software/hurd/user/jkoenig.html",
                        "level": 1,
                        "children": {
                            "java": {
                                "url": "https://www.gnu.org/software/hurd/user/jkoenig/java.html",
                                "level": 2,
                                "children": {
                                    "discussion": {
                                        "url": "https://www.gnu.org/software/hurd/user/jkoenig/java/discussion.html",
                                        "level": 3
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return self._flatten_structure(structure_data)
    
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
        return key.replace('_', ' ').title()
    
    def generate_actionable_steps(self, item: IssueItem) -> List[str]:
        """Generate actionable steps for an issue based on its type and level."""
        steps = []
        
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
        
        # Special handling for specific categories
        if "open_issues" in item.title.lower():
            steps.extend([
                "Investigate root cause",
                "Propose solution approach",
                "Estimate effort and timeline",
                "Create implementation plan"
            ])
        elif "performance" in item.title.lower():
            steps.extend([
                "Benchmark current performance",
                "Identify bottlenecks",
                "Implement optimizations",
                "Measure improvements"
            ])
        elif "documentation" in item.title.lower():
            steps.extend([
                "Audit existing documentation",
                "Identify missing sections",
                "Write comprehensive guides",
                "Create examples and tutorials"
            ])
        
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

### Additional Notes
- This issue was automatically generated from the open issues documentation structure
- Priority should be assigned based on current project needs
- Consider dependencies with related issues

### Labels
- `documentation`
- `enhancement`
- `automated-issue`
"""
        
        return body
    
    def create_github_issue(self, item: IssueItem) -> Optional[Dict]:
        """Create a GitHub issue for the given item."""
        if not self.github_token:
            print(f"Would create issue: {item.title}")
            return None
        
        headers = {
            'Authorization': f'token {self.github_token}',
            'Accept': 'application/vnd.github.v3+json'
        }
        
        data = {
            'title': f"Documentation: {item.title}",
            'body': self.create_issue_body(item),
            'labels': ['documentation', 'enhancement', 'automated-issue']
        }
        
        try:
            response = requests.post(
                f"{self.api_base}/issues",
                headers=headers,
                json=data
            )
            
            if response.status_code == 201:
                print(f"Created issue: {item.title}")
                return response.json()
            else:
                print(f"Failed to create issue for {item.title}: {response.status_code}")
                return None
                
        except Exception as e:
            print(f"Error creating issue for {item.title}: {e}")
            return None
    
    def run(self):
        """Main execution method."""
        print("Parsing open issues documentation structure...")
        items = self.parse_documentation_structure()
        
        print(f"Found {len(items)} items to process")
        
        # Create issues for each item
        created_issues = []
        for item in items:
            issue = self.create_github_issue(item)
            if issue:
                created_issues.append(issue)
        
        print(f"Successfully created {len(created_issues)} issues")
        
        # Save the structure to a JSON file for reference
        with open('open_issues_structure.json', 'w') as f:
            json.dump([{
                'title': item.title,
                'url': item.url,
                'level': item.level,
                'parent': item.parent,
                'actionable_steps': self.generate_actionable_steps(item)
            } for item in items], f, indent=2)
        
        print("Saved structure to open_issues_structure.json")

if __name__ == "__main__":
    generator = IssueGenerator()
    generator.run()