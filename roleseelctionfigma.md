<!DOCTYPE html>

<html class="light" lang="en"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0, viewport-fit=cover" name="viewport"/>
<title>Account Type Selection</title>
<link href="https://fonts.googleapis.com" rel="preconnect"/>
<link crossorigin="" href="https://fonts.gstatic.com" rel="preconnect"/>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500&amp;family=Plus+Jakarta+Sans:wght@600;700;800&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<script id="tailwind-config">
        tailwind.config = {
            darkMode: "class",
            theme: {
                extend: {
                    "colors": {
                        "on-background": "#1a1c1e",
                        "secondary-container": "#e0e2ec",
                        "outline-variant": "#c4c6d0",
                        "tertiary-fixed-dim": "#f7fafd",
                        "on-tertiary-fixed-variant": "#0052cc",
                        "error": "#ba1a1a",
                        "on-tertiary-container": "#001d4d",
                        "on-error": "#ffffff",
                        "surface-tint": "#0052cc",
                        "surface-container": "#ffffff",
                        "inverse-on-surface": "#f1f0f4",
                        "on-primary-fixed-variant": "#001d4d",
                        "on-tertiary": "#ffffff",
                        "tertiary-fixed": "#d9e2ff",
                        "surface": "#f7fafd",
                        "outline": "#74777f",
                        "secondary-fixed-dim": "#bfc6dc",
                        "surface-container-lowest": "#ffffff",
                        "surface-container-low": "#f1f4f7",
                        "on-secondary-fixed-variant": "#3f4759",
                        "on-primary-container": "#ffffff",
                        "on-primary-fixed": "#001d4d",
                        "inverse-primary": "#d1e4ff",
                        "on-secondary-container": "#101c2b",
                        "secondary-fixed": "#dbe2f9",
                        "surface-variant": "#e1e2ec",
                        "on-secondary-fixed": "#101c2b",
                        "background": "#f7fafd",
                        "surface-dim": "#d7dadd",
                        "on-primary": "#ffffff",
                        "primary-container": "#0052cc",
                        "inverse-surface": "#2f3033",
                        "error-container": "#ffdad6",
                        "surface-bright": "#f7fafd",
                        "primary-fixed": "#d1e4ff",
                        "surface-container-highest": "#e1e3e8",
                        "on-surface": "#1a1c1e",
                        "tertiary-container": "#d9e2ff",
                        "secondary": "#585e71",
                        "primary-fixed-dim": "#d1e4ff",
                        "on-error-container": "#410002",
                        "primary": "#0052cc",
                        "on-surface-variant": "#44474e",
                        "surface-container-high": "#e7eaed",
                        "tertiary": "#0052cc",
                        "on-secondary": "#ffffff",
                        "on-tertiary-fixed": "#001d4d"
                    },
                    "borderRadius": {
                        "DEFAULT": "0.25rem",
                        "lg": "0.5rem",
                        "xl": "0.75rem",
                        "full": "9999px"
                    },
                    "spacing": {
                        "gutter-md": "16px",
                        "container-padding": "24px",
                        "stack-gap": "12px",
                        "margin-mobile": "20px",
                        "section-padding": "32px"
                    },
                    "fontFamily": {
                        "body-md": ["Inter"],
                        "label-sm": ["Inter"],
                        "headline-lg": ["Plus Jakarta Sans"],
                        "display-lg": ["Plus Jakarta Sans"],
                        "headline-lg-mobile": ["Plus Jakarta Sans"],
                        "title-md": ["Plus Jakarta Sans"]
                    },
                    "fontSize": {
                        "body-md": ["16px", {"lineHeight": "24px", "fontWeight": "400"}],
                        "label-sm": ["12px", {"lineHeight": "16px", "letterSpacing": "0.05em", "fontWeight": "500"}],
                        "headline-lg": ["24px", {"lineHeight": "32px", "fontWeight": "700"}],
                        "display-lg": ["40px", {"lineHeight": "48px", "letterSpacing": "-0.02em", "fontWeight": "600"}],
                        "headline-lg-mobile": ["22px", {"lineHeight": "28px", "fontWeight": "700"}],
                        "title-md": ["18px", {"lineHeight": "24px", "fontWeight": "600"}]
                    }
                },
            },
        }
    </script>
<style>
        .material-symbols-outlined {
            font-variation-settings: 'FILL' 0, 'wght' 400, 'GRAD' 0, 'opsz' 24;
        }
        .azure-shadow {
            box-shadow: 0 4px 20px rgba(0, 82, 204, 0.08);
        }
        .glass-badge {
            background: rgba(0, 82, 204, 0.08);
            backdrop-filter: blur(8px);
        }
    </style>
<style>
        body {
            min-height: max(884px, 100dvh);
        }
    </style>
</head>
<body class="bg-background text-on-background font-body-md selection:bg-primary/20 overflow-x-hidden">
<!-- Top App Bar -->
<header class="fixed top-0 left-0 w-full z-50 bg-background/80 backdrop-blur-lg">
<div class="flex items-center px-gutter-md h-16 w-full max-w-7xl mx-auto">
<button class="material-symbols-outlined text-primary p-2 rounded-full hover:bg-primary/5 active:scale-95 transition-transform" data-icon="arrow_back">
            arrow_back
        </button>
<h1 class="ml-4 font-headline-lg-mobile text-headline-lg-mobile text-on-background truncate">
            Select Your Account Type
        </h1>
</div>
</header>
<main class="pt-24 pb-12 px-gutter-md min-h-screen flex flex-col max-w-lg mx-auto">
<!-- Hero Section Visual -->
<div class="relative w-full aspect-[16/10] mb-8 flex items-center justify-between overflow-visible">
<div class="z-10 max-w-[60%]">
<h2 class="font-display-lg text-display-lg leading-tight text-on-background mb-2">
                Select your <span class="text-primary">preference</span>
</h2>
</div>
<div class="absolute right-[-10%] top-0 w-[60%] aspect-square rounded-full bg-surface-container-high flex items-center justify-center">
<img class="w-full h-full object-cover rounded-full mix-blend-multiply opacity-90" data-alt="A professional barber wearing a black uniform and protective face mask meticulously cutting a client's hair in a high-end, dark-toned luxury grooming salon." src="https://lh3.googleusercontent.com/aida-public/AB6AXuAW_0z4mXIM1BBgS5LEXEU4reUxEViGzO8KRvxTqZMTdSnJQ5qVntIjGD6X--755BlHTvWHrFTxzNqUC4_UIOBgo05XNlbvnVOw14gMekfbq16oMAtusZ1dXMazN9dD_NUXDBSXBN3I3hyEF0FfPrH9U3Z3Kha6prj_I_TY2HycU-5GfXd59G4X4TCTsdjacbRZmZuS2DyDoxXxKoCEZNONW2Us5EptskfqYUsXOg4wNVTT4xMCVmdvsdF6o5rkPxjl2VGS1o3j1QI"/>
</div>
</div>
<div class="space-y-6">
<!-- Individual Card -->
<div class="bg-surface-container border border-outline-variant/30 rounded-lg p-container-padding flex flex-col azure-shadow group transition-all duration-300 hover:border-primary/30">
<div class="flex justify-between items-start mb-4">
<div class="w-12 h-12 rounded-lg bg-surface-container-high flex items-center justify-center">
<span class="material-symbols-outlined text-primary text-3xl" data-icon="person">person</span>
</div>
<span class="glass-badge px-3 py-1 rounded-full text-label-sm font-label-sm text-primary uppercase tracking-widest">
                    Prime
                </span>
</div>
<h3 class="font-headline-lg-mobile text-headline-lg-mobile text-on-background mb-2">Individual</h3>
<p class="text-on-surface-variant font-body-md mb-6 leading-relaxed">
                For personal grooming and styling services. Get access to top-rated stylists and personalized care.
            </p>
<div class="space-y-3 mb-8">
<div class="flex items-center gap-3">
<span class="material-symbols-outlined text-primary text-sm" data-icon="star" data-weight="fill" style="font-variation-settings: 'FILL' 1;">star</span>
<span class="text-label-sm font-label-sm text-on-surface-variant">4.5+ rated stylists</span>
</div>
<div class="flex items-center gap-3">
<span class="material-symbols-outlined text-primary text-sm" data-icon="verified" data-weight="fill" style="font-variation-settings: 'FILL' 1;">verified</span>
<span class="text-label-sm font-label-sm text-on-surface-variant">Personalized routines</span>
</div>
</div>
<div class="mt-auto pt-6 border-t border-dotted border-outline-variant flex items-center justify-between">
<div class="text-on-surface-variant font-label-sm text-label-sm flex items-center gap-2">
<span class="material-symbols-outlined text-lg" data-icon="branding_watermark">branding_watermark</span>
                    L'ORÉAL PARTNER
                </div>
<button class="bg-primary text-on-primary px-6 py-2.5 rounded-full font-label-sm text-label-sm font-bold active:scale-95 transition-transform hover:brightness-110">
                    Get Started
                </button>
</div>
</div>
<!-- Organization Card -->
<div class="bg-primary-container border border-primary/20 rounded-lg p-container-padding flex flex-col azure-shadow transition-all duration-300 hover:brightness-105">
<div class="flex justify-between items-start mb-4">
<div class="w-12 h-12 rounded-lg bg-white/10 flex items-center justify-center">
<span class="material-symbols-outlined text-white text-3xl" data-icon="corporate_fare">corporate_fare</span>
</div>
<span class="bg-white/10 px-3 py-1 rounded-full text-label-sm font-label-sm text-white uppercase tracking-widest">
                    Royale
                </span>
</div>
<h3 class="font-headline-lg-mobile text-headline-lg-mobile text-white mb-2">Organization</h3>
<p class="text-white/80 font-body-md mb-6 leading-relaxed">
                For managing teams, salons, and corporate grooming packages. Unified dashboard and exclusive rates.
            </p>
<div class="space-y-3 mb-8">
<div class="flex items-center gap-3">
<span class="material-symbols-outlined text-white/90 text-sm" data-icon="stars" data-weight="fill" style="font-variation-settings: 'FILL' 1;">stars</span>
<span class="text-label-sm font-label-sm text-white/90">Exclusive corporate rates</span>
</div>
<div class="flex items-center gap-3">
<span class="material-symbols-outlined text-white/90 text-sm" data-icon="analytics" data-weight="fill" style="font-variation-settings: 'FILL' 1;">analytics</span>
<span class="text-label-sm font-label-sm text-white/90">Team management console</span>
</div>
</div>
<div class="mt-auto pt-6 border-t border-dotted border-white/20 flex items-center justify-between">
<div class="text-white/80 font-label-sm text-label-sm flex items-center gap-2">
<span class="material-symbols-outlined text-lg" data-icon="workspace_premium">workspace_premium</span>
                    ENTERPRISE TIER
                </div>
<button class="bg-white text-primary px-6 py-2.5 rounded-full font-label-sm text-label-sm font-bold active:scale-95 transition-transform hover:shadow-xl">
                    Get Started
                </button>
</div>
</div>
</div>
</main>
<script>
    // Micro-interaction for hover effects on cards
    document.querySelectorAll('.bg-surface-container, .bg-primary-container').forEach(card => {
        card.addEventListener('mousedown', () => {
            card.style.transform = 'scale(0.98)';
        });
        card.addEventListener('mouseup', () => {
            card.style.transform = 'scale(1)';
        });
        card.addEventListener('mouseleave', () => {
            card.style.transform = 'scale(1)';
        });
    });
</script>
</body></html>