<!-- New Batch - Permissions -->
<!DOCTYPE html>

<html class="light" lang="en"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<link href="https://fonts.googleapis.com/css2?family=Sora:wght@400;500;600;700;800&amp;family=Inter:wght@400;500;600&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<script id="tailwind-config">
        tailwind.config = {
          darkMode: "class",
          theme: {
            extend: {
              "colors": {
                      "on-secondary-container": "#394c84",
                      "surface-container-high": "#e7e7f3",
                      "on-primary-container": "#eeefff",
                      "surface-container": "#ededf9",
                      "inverse-surface": "#2e3039",
                      "tertiary-fixed": "#ffdbcd",
                      "on-primary-fixed-variant": "#003ea8",
                      "error-container": "#ffdad6",
                      "secondary-fixed": "#dbe1ff",
                      "on-primary": "#ffffff",
                      "on-error": "#ffffff",
                      "surface-variant": "#e1e2ed",
                      "on-surface-variant": "#434655",
                      "on-tertiary-container": "#ffede6",
                      "inverse-primary": "#b4c5ff",
                      "on-surface": "#191b23",
                      "tertiary": "#943700",
                      "on-tertiary-fixed": "#360f00",
                      "tertiary-fixed-dim": "#ffb596",
                      "primary-fixed-dim": "#b4c5ff",
                      "on-secondary-fixed-variant": "#31447b",
                      "on-error-container": "#93000a",
                      "error": "#ba1a1a",
                      "primary-fixed": "#dbe1ff",
                      "primary-container": "#2563eb",
                      "surface-bright": "#faf8ff",
                      "tertiary-container": "#bc4800",
                      "surface-container-lowest": "#ffffff",
                      "on-primary-fixed": "#00174b",
                      "on-secondary": "#ffffff",
                      "on-secondary-fixed": "#00174b",
                      "outline": "#737686",
                      "on-background": "#191b23",
                      "surface-dim": "#d9d9e5",
                      "secondary-fixed-dim": "#b4c5ff",
                      "secondary-container": "#acbfff",
                      "inverse-on-surface": "#f0f0fb",
                      "secondary": "#495c95",
                      "on-tertiary": "#ffffff",
                      "surface": "#faf8ff",
                      "on-tertiary-fixed-variant": "#7d2d00",
                      "outline-variant": "#c3c6d7",
                      "surface-tint": "#0053db",
                      "surface-container-low": "#f3f3fe",
                      "background": "#faf8ff",
                      "primary": "#004ac6",
                      "surface-container-highest": "#e1e2ed"
              },
              "borderRadius": {
                      "DEFAULT": "0.25rem",
                      "lg": "0.5rem",
                      "xl": "0.75rem",
                      "full": "9999px"
              },
              "spacing": {
                      "container-padding": "20px",
                      "inline-gutter": "12px",
                      "stack-gap": "16px",
                      "section-gap": "24px"
              },
              "fontFamily": {
                      "metadata": ["Inter"],
                      "h2": ["Sora"],
                      "label-md": ["Sora"],
                      "h3": ["Sora"],
                      "body-lg": ["Inter"],
                      "h1": ["Sora"],
                      "body-sm": ["Inter"]
              },
              "fontSize": {
                      "metadata": ["12px", {"fontWeight": "500"}],
                      "h2": ["22px", {"lineHeight": "28px", "letterSpacing": "-0.01em", "fontWeight": "600"}],
                      "label-md": ["14px", {"lineHeight": "18px", "fontWeight": "600"}],
                      "h3": ["18px", {"lineHeight": "24px", "fontWeight": "600"}],
                      "body-lg": ["16px", {"lineHeight": "24px", "fontWeight": "400"}],
                      "h1": ["28px", {"lineHeight": "36px", "letterSpacing": "-0.02em", "fontWeight": "700"}],
                      "body-sm": ["14px", {"lineHeight": "20px", "fontWeight": "400"}]
              }
            },
          },
        }
    </script>
<style>
        body { background-color: #F0F4FF; }
        .primary-gradient { background: linear-gradient(135deg, #0053db 0%, #2563eb 100%); }
        .material-symbols-outlined { font-variation-settings: 'FILL' 0, 'wght' 400, 'GRAD' 0, 'opsz' 24; }
    </style>
</head>
<body class="font-body-lg text-on-surface min-h-screen flex flex-col">
<!-- TopAppBar -->
<header class="bg-white dark:bg-slate-900 border-b border-blue-50/50 dark:border-slate-800 shadow-[0_2px_12px_rgba(37,99,235,0.08)] flex justify-between items-center w-full px-5 h-16 sticky top-0 z-50">
<div class="flex items-center gap-4">
<button class="w-10 h-10 flex items-center justify-center rounded-full hover:bg-blue-50 transition-colors">
<span class="material-symbols-outlined text-primary">arrow_back</span>
</button>
<h1 class="font-h2 text-h2 text-on-surface">Create New Batch</h1>
</div>
<div class="flex items-center gap-2">
<button class="p-2 hover:bg-blue-50 dark:hover:bg-slate-800 transition-colors rounded-full">
<span class="material-symbols-outlined text-slate-500">notifications</span>
</button>
<button class="p-2 hover:bg-blue-50 dark:hover:bg-slate-800 transition-colors rounded-full">
<span class="material-symbols-outlined text-slate-500">help_outline</span>
</button>
</div>
</header>
<main class="flex-grow max-w-2xl mx-auto w-full px-container-padding py-section-gap">
<!-- Progress Stepper -->
<nav class="mb-section-gap flex items-center justify-between px-2">
<div class="flex flex-col items-center gap-2">
<div class="w-8 h-8 rounded-full bg-primary-container text-white flex items-center justify-center font-bold text-sm">1</div>
<span class="font-metadata text-metadata text-slate-500">Industry</span>
</div>
<div class="flex-grow h-[2px] bg-primary-container/20 mx-4 mt-[-20px]"></div>
<div class="flex flex-col items-center gap-2">
<div class="w-8 h-8 rounded-full bg-primary-container text-white flex items-center justify-center font-bold text-sm">2</div>
<span class="font-metadata text-metadata text-slate-500">Checks</span>
</div>
<div class="flex-grow h-[2px] bg-primary-container/20 mx-4 mt-[-20px]"></div>
<div class="flex flex-col items-center gap-2">
<div class="w-8 h-8 rounded-full primary-gradient text-white flex items-center justify-center font-bold text-sm ring-4 ring-primary/10">3</div>
<span class="font-metadata text-metadata text-primary font-semibold">Permissions</span>
</div>
</nav>
<!-- Main Content -->
<section class="space-y-stack-gap">
<h2 class="font-h1 text-h1 mb-4">Configure Permissions</h2>
<div class="grid grid-cols-1 gap-4">
<!-- Selection Card: Public -->
<label class="relative block group cursor-pointer">
<input checked="" class="peer sr-only" name="access_type" type="radio"/>
<div class="p-5 bg-white rounded-[20px] shadow-[0_2px_12px_rgba(37,99,235,0.08)] border-2 border-transparent peer-checked:border-primary peer-checked:bg-blue-50/30 transition-all">
<div class="flex items-start justify-between">
<div class="flex-1">
<div class="flex items-center gap-3 mb-2">
<div class="w-10 h-10 rounded-xl bg-blue-100 flex items-center justify-center">
<span class="material-symbols-outlined text-primary">public</span>
</div>
<h3 class="font-h3 text-h3">Public Searchable</h3>
</div>
<p class="font-body-sm text-body-sm text-on-surface-variant">Results will be visible in the public registry for instant verification.</p>
</div>
<div class="w-6 h-6 rounded-full border-2 border-outline group-hover:border-primary peer-checked:border-primary peer-checked:bg-primary flex items-center justify-center">
<div class="w-2.5 h-2.5 rounded-full bg-white opacity-0 peer-checked:opacity-100 transition-opacity"></div>
</div>
</div>
</div>
</label>
<!-- Selection Card: Permission-Based -->
<label class="relative block group cursor-pointer">
<input class="peer sr-only" name="access_type" type="radio"/>
<div class="p-5 bg-white rounded-[20px] shadow-[0_2px_12px_rgba(37,99,235,0.08)] border-2 border-transparent peer-checked:border-primary peer-checked:bg-blue-50/30 transition-all">
<div class="flex items-start justify-between">
<div class="flex-1">
<div class="flex items-center gap-3 mb-2">
<div class="w-10 h-10 rounded-xl bg-blue-100 flex items-center justify-center">
<span class="material-symbols-outlined text-primary">lock_person</span>
</div>
<h3 class="font-h3 text-h3">Permission-Based Access</h3>
</div>
<p class="font-body-sm text-body-sm text-on-surface-variant">Requires explicit consent via WhatsApp or Email from the individual before data access.</p>
</div>
<div class="w-6 h-6 rounded-full border-2 border-outline group-hover:border-primary flex items-center justify-center">
<div class="w-2.5 h-2.5 rounded-full bg-white opacity-0 transition-opacity"></div>
</div>
</div>
<!-- Nested Consent Details (Visible when parent peer is checked - simulated with opacity for static HTML) -->
<div class="mt-6 pt-6 border-t border-slate-100 space-y-4">
<h4 class="font-label-md text-label-md text-primary uppercase tracking-wider">Consent Channels</h4>
<div class="flex items-center justify-between p-4 bg-surface-container-low rounded-xl">
<div class="flex items-center gap-3">
<span class="material-symbols-outlined text-on-surface-variant">chat</span>
<span class="font-body-lg text-body-lg">WhatsApp Consent</span>
</div>
<div class="relative inline-flex items-center cursor-pointer">
<input checked="" class="sr-only peer" type="checkbox" value=""/>
<div class="w-11 h-6 bg-slate-300 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary"></div>
</div>
</div>
<div class="flex items-center justify-between p-4 bg-surface-container-low rounded-xl">
<div class="flex items-center gap-3">
<span class="material-symbols-outlined text-on-surface-variant">mail</span>
<span class="font-body-lg text-body-lg">Email Consent</span>
</div>
<div class="relative inline-flex items-center cursor-pointer">
<input class="sr-only peer" type="checkbox" value=""/>
<div class="w-11 h-6 bg-slate-300 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary"></div>
</div>
</div>
</div>
</div>
</label>
</div>
<!-- Informational Banner -->
<div class="bg-blue-50/50 p-5 rounded-[20px] flex gap-4 border border-blue-100">
<span class="material-symbols-outlined text-primary shrink-0" style="font-variation-settings: 'FILL' 1;">info</span>
<p class="font-body-sm text-body-sm text-on-secondary-container">
                    TruMarkZ uses cryptographic signing for every consent request. Selecting <strong>Permission-Based Access</strong> ensures GDPR and SOC2 compliance for sensitive professional data.
                </p>
</div>
</section>
<!-- Identity Highlight Card (Bento Style) -->
<div class="mt-12 bg-white p-6 rounded-[20px] shadow-[0_2px_12px_rgba(37,99,235,0.08)] relative overflow-hidden group">
<div class="absolute top-0 right-0 w-32 h-32 primary-gradient rounded-bl-full opacity-5 group-hover:scale-110 transition-transform"></div>
<div class="flex flex-col md:flex-row items-center gap-6">
<div class="w-24 h-24 rounded-2xl overflow-hidden shrink-0 shadow-lg">
<img alt="System Preview" class="w-full h-full object-cover" data-alt="A clean, minimalist 3D rendering of a translucent blue shield icon floating in a bright, modern digital space. The background is a soft, high-key white with subtle blue-tinted gradients. Sharp focus on geometric precision and light refraction through glass-like surfaces, embodying a secure and corporate institutional identity." src="https://lh3.googleusercontent.com/aida-public/AB6AXuDef_roIlhTk2MVxBne6O8e7qVHqs5wbvJNB6BRkZqRwSuKcAvNP_9ja7lx7YCChuqm9osYRLb9zAWDyzelLeEUzz7tfCfFwUqn_hQ1QLcc3mlaXwpzO_xyv8pnRvp-gxZaQDXkX3qyIxXadQ60gqdhAKIXGIEnjJnBuio1VOr8jnkRBmsehMpWjoskBs5DsopN-BXCdfJCZRW4SlWygymPxKN9N-KkjifQ4-eqsfL0PB77_UDrw2oiv1gYfXfvHCjXrkCUhELrXno"/>
</div>
<div>
<div class="flex items-center gap-2 mb-2">
<div class="bg-blue-100 text-primary px-3 py-1 rounded-full flex items-center gap-1.5">
<span class="material-symbols-outlined text-sm" style="font-variation-settings: 'FILL' 1;">verified</span>
<span class="font-metadata text-[10px] font-bold uppercase tracking-widest">TruMarkZ Standard</span>
</div>
</div>
<h4 class="font-h3 text-h3 mb-1">Batch Integrity Protection</h4>
<p class="font-body-sm text-on-surface-variant">Each batch generated is anchored to the blockchain, ensuring that once permissions are set, they are immutable and verifiable by third parties.</p>
</div>
</div>
</div>
</main>
<!-- Footer Action -->
<footer class="sticky bottom-0 bg-white/95 backdrop-blur-md border-t border-slate-100 p-container-padding flex justify-center z-50">
<button class="primary-gradient w-full max-w-md h-[54px] rounded-full text-white font-label-md text-body-lg flex items-center justify-center gap-2 shadow-lg shadow-primary/20 hover:scale-[1.02] active:scale-95 transition-all">
<span>Finalize &amp; Create Batch</span>
<span class="material-symbols-outlined">rocket_launch</span>
</button>
</footer>
<!-- BottomNavBar (Hidden on desktop as per Shell Visibility rules) -->
<nav class="md:hidden fixed bottom-0 left-0 w-full h-[64px] bg-white/95 backdrop-blur-md border-t border-slate-100 flex justify-around items-center px-4 pb-safe hidden">
<div class="flex flex-col items-center justify-center text-slate-400">
<span class="material-symbols-outlined" data-icon="list_alt">list_alt</span>
<span class="font-metadata text-[10px]">Batches</span>
</div>
<div class="flex flex-col items-center justify-center text-slate-400">
<span class="material-symbols-outlined" data-icon="verified_user">verified_user</span>
<span class="font-metadata text-[10px]">Verification</span>
</div>
<div class="flex flex-col items-center justify-center text-slate-400">
<span class="material-symbols-outlined" data-icon="folder_shared">folder_shared</span>
<span class="font-metadata text-[10px]">Directory</span>
</div>
<div class="flex flex-col items-center justify-center text-primary after:content-[''] after:w-1 after:h-1 after:bg-primary after:rounded-full after:mt-1">
<span class="material-symbols-outlined" data-icon="settings">settings</span>
<span class="font-metadata text-[10px]">Settings</span>
</div>
</nav>
</body></html>

<!-- New Batch - Select Industry -->
<!DOCTYPE html>

<html lang="en"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<link href="https://fonts.googleapis.com/css2?family=Sora:wght@400;500;600;700;800&amp;family=Inter:wght@400;500;600&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<script id="tailwind-config">
        tailwind.config = {
            darkMode: "class",
            theme: {
                extend: {
                    "colors": {
                        "on-secondary-container": "#394c84",
                        "surface-container-high": "#e7e7f3",
                        "on-primary-container": "#eeefff",
                        "surface-container": "#ededf9",
                        "inverse-surface": "#2e3039",
                        "tertiary-fixed": "#ffdbcd",
                        "on-primary-fixed-variant": "#003ea8",
                        "error-container": "#ffdad6",
                        "secondary-fixed": "#dbe1ff",
                        "on-primary": "#ffffff",
                        "on-error": "#ffffff",
                        "surface-variant": "#e1e2ed",
                        "on-surface-variant": "#434655",
                        "on-tertiary-container": "#ffede6",
                        "inverse-primary": "#b4c5ff",
                        "on-surface": "#191b23",
                        "tertiary": "#943700",
                        "on-tertiary-fixed": "#360f00",
                        "tertiary-fixed-dim": "#ffb596",
                        "primary-fixed-dim": "#b4c5ff",
                        "on-secondary-fixed-variant": "#31447b",
                        "on-error-container": "#93000a",
                        "error": "#ba1a1a",
                        "primary-fixed": "#dbe1ff",
                        "primary-container": "#2563eb",
                        "surface-bright": "#faf8ff",
                        "tertiary-container": "#bc4800",
                        "surface-container-lowest": "#ffffff",
                        "on-primary-fixed": "#00174b",
                        "on-secondary": "#ffffff",
                        "on-secondary-fixed": "#00174b",
                        "outline": "#737686",
                        "on-background": "#191b23",
                        "surface-dim": "#d9d9e5",
                        "secondary-fixed-dim": "#b4c5ff",
                        "secondary-container": "#acbfff",
                        "inverse-on-surface": "#f0f0fb",
                        "secondary": "#495c95",
                        "on-tertiary": "#ffffff",
                        "surface": "#faf8ff",
                        "on-tertiary-fixed-variant": "#7d2d00",
                        "outline-variant": "#c3c6d7",
                        "surface-tint": "#0053db",
                        "surface-container-low": "#f3f3fe",
                        "background": "#faf8ff",
                        "primary": "#004ac6",
                        "surface-container-highest": "#e1e2ed"
                    },
                    "borderRadius": {
                        "DEFAULT": "0.25rem",
                        "lg": "0.5rem",
                        "xl": "0.75rem",
                        "full": "9999px"
                    },
                    "spacing": {
                        "container-padding": "20px",
                        "inline-gutter": "12px",
                        "stack-gap": "16px",
                        "section-gap": "24px"
                    },
                    "fontFamily": {
                        "metadata": ["Inter"],
                        "h2": ["Sora"],
                        "label-md": ["Sora"],
                        "h3": ["Sora"],
                        "body-lg": ["Inter"],
                        "h1": ["Sora"],
                        "body-sm": ["Inter"]
                    },
                    "fontSize": {
                        "metadata": ["12px", {"fontWeight": "500"}],
                        "h2": ["22px", {"lineHeight": "28px", "letterSpacing": "-0.01em", "fontWeight": "600"}],
                        "label-md": ["14px", {"lineHeight": "18px", "fontWeight": "600"}],
                        "h3": ["18px", {"lineHeight": "24px", "fontWeight": "600"}],
                        "body-lg": ["16px", {"lineHeight": "24px", "fontWeight": "400"}],
                        "h1": ["28px", {"lineHeight": "36px", "letterSpacing": "-0.02em", "fontWeight": "700"}],
                        "body-sm": ["14px", {"lineHeight": "20px", "fontWeight": "400"}]
                    }
                },
            },
        }
    </script>
<style>
        body {
            background-color: #F0F4FF;
        }
        .primary-gradient {
            background: linear-gradient(135deg, #2563eb 0%, #004ac6 100%);
        }
        .ambient-shadow {
            box-shadow: 0 2px 12px rgba(37,99,235,0.08);
        }
        .recessed-border {
            border: 1px solid #E2E8F0;
            background-color: #F8FAFF;
        }
    </style>
</head>
<body class="font-body-lg text-on-surface antialiased min-h-screen flex flex-col">
<!-- TopAppBar -->
<header class="bg-white dark:bg-slate-900 border-b border-blue-50/50 dark:border-slate-800 shadow-[0_2px_12px_rgba(37,99,235,0.08)] sticky top-0 z-50 flex justify-between items-center w-full px-5 h-16">
<div class="flex items-center gap-3">
<button class="flex items-center justify-center w-10 h-10 rounded-full hover:bg-blue-50 dark:hover:bg-slate-800 transition-colors">
<span class="material-symbols-outlined text-blue-600">arrow_back</span>
</button>
<h1 class="font-['Sora'] font-semibold text-lg text-slate-900 dark:text-white">Create New Batch</h1>
</div>
<div class="flex items-center gap-2">
<button class="w-10 h-10 flex items-center justify-center rounded-full hover:bg-blue-50 dark:hover:bg-slate-800 transition-colors text-slate-500 dark:text-slate-400">
<span class="material-symbols-outlined">notifications</span>
</button>
<button class="w-10 h-10 flex items-center justify-center rounded-full hover:bg-blue-50 dark:hover:bg-slate-800 transition-colors text-slate-500 dark:text-slate-400">
<span class="material-symbols-outlined">help_outline</span>
</button>
</div>
</header>
<main class="flex-1 max-w-4xl mx-auto w-full px-container-padding py-section-gap pb-32">
<!-- Progress Stepper -->
<nav class="mb-section-gap">
<div class="flex items-center justify-between overflow-x-auto pb-4 gap-4 no-scrollbar">
<div class="flex items-center gap-3 min-w-max">
<div class="flex items-center justify-center w-8 h-8 rounded-full primary-gradient text-white text-xs font-bold">1</div>
<span class="font-label-md text-label-md text-primary">Industry Selection</span>
</div>
<div class="h-[1px] flex-1 min-w-[24px] bg-outline-variant"></div>
<div class="flex items-center gap-3 min-w-max opacity-50">
<div class="flex items-center justify-center w-8 h-8 rounded-full bg-surface-container text-on-surface-variant text-xs font-bold">2</div>
<span class="font-label-md text-label-md text-on-surface-variant">Checks &amp; Cost</span>
</div>
<div class="h-[1px] flex-1 min-w-[24px] bg-outline-variant"></div>
<div class="flex items-center gap-3 min-w-max opacity-50">
<div class="flex items-center justify-center w-8 h-8 rounded-full bg-surface-container text-on-surface-variant text-xs font-bold">3</div>
<span class="font-label-md text-label-md text-on-surface-variant">Permissions</span>
</div>
</div>
</nav>
<!-- Heading Section -->
<header class="mb-stack-gap">
<h2 class="font-h1 text-h1 text-on-surface mb-2">Select Industry</h2>
<p class="font-body-sm text-body-sm text-on-surface-variant">Choose the industry category that best fits this credential batch for optimized verification workflows.</p>
</header>
<!-- Industry Bento/Grid -->
<section class="grid grid-cols-2 md:grid-cols-4 gap-4 mt-section-gap">
<!-- Selected Card: Transport -->
<div class="relative group cursor-pointer bg-white rounded-[20px] p-container-padding ambient-shadow border-2 border-primary ring-4 ring-primary/5 flex flex-col items-center justify-center text-center aspect-square transition-all transform active:scale-95">
<div class="w-14 h-14 rounded-full bg-primary/10 flex items-center justify-center mb-4 text-primary">
<span class="material-symbols-outlined text-3xl" data-weight="fill">local_shipping</span>
</div>
<span class="font-label-md text-label-md text-primary">Transport</span>
<div class="absolute top-3 right-3 w-6 h-6 primary-gradient rounded-full flex items-center justify-center">
<span class="material-symbols-outlined text-white text-base">check</span>
</div>
</div>
<!-- Healthcare -->
<div class="group cursor-pointer bg-white rounded-[20px] p-container-padding ambient-shadow border border-transparent hover:border-primary/20 flex flex-col items-center justify-center text-center aspect-square transition-all transform active:scale-95">
<div class="w-14 h-14 rounded-full bg-blue-50 flex items-center justify-center mb-4 text-blue-600 transition-colors group-hover:bg-primary group-hover:text-white">
<span class="material-symbols-outlined text-3xl">medical_services</span>
</div>
<span class="font-label-md text-label-md text-on-surface">Healthcare</span>
</div>
<!-- Education -->
<div class="group cursor-pointer bg-white rounded-[20px] p-container-padding ambient-shadow border border-transparent hover:border-primary/20 flex flex-col items-center justify-center text-center aspect-square transition-all transform active:scale-95">
<div class="w-14 h-14 rounded-full bg-blue-50 flex items-center justify-center mb-4 text-blue-600 transition-colors group-hover:bg-primary group-hover:text-white">
<span class="material-symbols-outlined text-3xl">school</span>
</div>
<span class="font-label-md text-label-md text-on-surface">Education</span>
</div>
<!-- Manufacturing -->
<div class="group cursor-pointer bg-white rounded-[20px] p-container-padding ambient-shadow border border-transparent hover:border-primary/20 flex flex-col items-center justify-center text-center aspect-square transition-all transform active:scale-95">
<div class="w-14 h-14 rounded-full bg-blue-50 flex items-center justify-center mb-4 text-blue-600 transition-colors group-hover:bg-primary group-hover:text-white">
<span class="material-symbols-outlined text-3xl">factory</span>
</div>
<span class="font-label-md text-label-md text-on-surface">Manufacturing</span>
</div>
<!-- Security -->
<div class="group cursor-pointer bg-white rounded-[20px] p-container-padding ambient-shadow border border-transparent hover:border-primary/20 flex flex-col items-center justify-center text-center aspect-square transition-all transform active:scale-95">
<div class="w-14 h-14 rounded-full bg-blue-50 flex items-center justify-center mb-4 text-blue-600 transition-colors group-hover:bg-primary group-hover:text-white">
<span class="material-symbols-outlined text-3xl">shield_person</span>
</div>
<span class="font-label-md text-label-md text-on-surface">Security</span>
</div>
<!-- Agriculture -->
<div class="group cursor-pointer bg-white rounded-[20px] p-container-padding ambient-shadow border border-transparent hover:border-primary/20 flex flex-col items-center justify-center text-center aspect-square transition-all transform active:scale-95">
<div class="w-14 h-14 rounded-full bg-blue-50 flex items-center justify-center mb-4 text-blue-600 transition-colors group-hover:bg-primary group-hover:text-white">
<span class="material-symbols-outlined text-3xl">agriculture</span>
</div>
<span class="font-label-md text-label-md text-on-surface">Agriculture</span>
</div>
<!-- Products -->
<div class="group cursor-pointer bg-white rounded-[20px] p-container-padding ambient-shadow border border-transparent hover:border-primary/20 flex flex-col items-center justify-center text-center aspect-square transition-all transform active:scale-95">
<div class="w-14 h-14 rounded-full bg-blue-50 flex items-center justify-center mb-4 text-blue-600 transition-colors group-hover:bg-primary group-hover:text-white">
<span class="material-symbols-outlined text-3xl">inventory_2</span>
</div>
<span class="font-label-md text-label-md text-on-surface">Products</span>
</div>
<!-- Others -->
<div class="group cursor-pointer bg-white rounded-[20px] p-container-padding ambient-shadow border border-transparent hover:border-primary/20 flex flex-col items-center justify-center text-center aspect-square transition-all transform active:scale-95">
<div class="w-14 h-14 rounded-full bg-blue-50 flex items-center justify-center mb-4 text-blue-600 transition-colors group-hover:bg-primary group-hover:text-white">
<span class="material-symbols-outlined text-3xl">more_horiz</span>
</div>
<span class="font-label-md text-label-md text-on-surface">Others</span>
</div>
</section>
<!-- Information Card -->
<div class="mt-section-gap bg-blue-50/50 rounded-xl p-5 border border-blue-100 flex gap-4">
<span class="material-symbols-outlined text-primary">info</span>
<div>
<p class="font-label-md text-on-surface mb-1">Why select an industry?</p>
<p class="font-body-sm text-on-surface-variant leading-relaxed">Selecting an industry helps TruMarkZ apply industry-specific verification protocols and templates, saving you time during the configuration stage.</p>
</div>
</div>
</main>
<!-- Sticky Footer -->
<footer class="fixed bottom-0 left-0 w-full bg-white/80 backdrop-blur-lg border-t border-slate-100 px-container-padding py-4 z-40">
<div class="max-w-4xl mx-auto flex flex-col md:flex-row items-center justify-between gap-4">
<div class="hidden md:block">
<p class="font-body-sm text-on-surface-variant">Step 1 of 3</p>
<p class="font-label-md text-on-surface">Industry Selection</p>
</div>
<button class="w-full md:w-auto h-[54px] px-12 primary-gradient text-white font-['Sora'] font-semibold rounded-full shadow-lg active:scale-[0.98] transition-all flex items-center justify-center gap-2">
                Continue
                <span class="material-symbols-outlined text-xl">arrow_forward</span>
</button>
</div>
</footer>
<!-- BottomNavBar (Hidden on desktop as per Shell Visibility Rules, though this is a transactional flow) -->
<!-- Note: Transactional pages suppress the main nav shell according to the "Destination Rule". 
         However, for the UI design task context, it's provided in the JSON, but suppressed here 
         as per "Automatic Suppression" rule for Task-Focused pages. -->
</body></html>

<!-- New Batch - Checks & Cost -->
<!DOCTYPE html>

<html class="light" lang="en"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<title>TruMarkZ - Create New Batch</title>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<link href="https://fonts.googleapis.com/css2?family=Sora:wght@400;500;600;700;800&amp;family=Inter:wght@400;500;600&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<script id="tailwind-config">
    tailwind.config = {
      darkMode: "class",
      theme: {
        extend: {
          "colors": {
                  "on-secondary-container": "#394c84",
                  "surface-container-high": "#e7e7f3",
                  "on-primary-container": "#eeefff",
                  "surface-container": "#ededf9",
                  "inverse-surface": "#2e3039",
                  "tertiary-fixed": "#ffdbcd",
                  "on-primary-fixed-variant": "#003ea8",
                  "error-container": "#ffdad6",
                  "secondary-fixed": "#dbe1ff",
                  "on-primary": "#ffffff",
                  "on-error": "#ffffff",
                  "surface-variant": "#e1e2ed",
                  "on-surface-variant": "#434655",
                  "on-tertiary-container": "#ffede6",
                  "inverse-primary": "#b4c5ff",
                  "on-surface": "#191b23",
                  "tertiary": "#943700",
                  "on-tertiary-fixed": "#360f00",
                  "tertiary-fixed-dim": "#ffb596",
                  "primary-fixed-dim": "#b4c5ff",
                  "on-secondary-fixed-variant": "#31447b",
                  "on-error-container": "#93000a",
                  "error": "#ba1a1a",
                  "primary-fixed": "#dbe1ff",
                  "primary-container": "#2563eb",
                  "surface-bright": "#faf8ff",
                  "tertiary-container": "#bc4800",
                  "surface-container-lowest": "#ffffff",
                  "on-primary-fixed": "#00174b",
                  "on-secondary": "#ffffff",
                  "on-secondary-fixed": "#00174b",
                  "outline": "#737686",
                  "on-background": "#191b23",
                  "surface-dim": "#d9d9e5",
                  "secondary-fixed-dim": "#b4c5ff",
                  "secondary-container": "#acbfff",
                  "inverse-on-surface": "#f0f0fb",
                  "secondary": "#495c95",
                  "on-tertiary": "#ffffff",
                  "surface": "#faf8ff",
                  "on-tertiary-fixed-variant": "#7d2d00",
                  "outline-variant": "#c3c6d7",
                  "surface-tint": "#0053db",
                  "surface-container-low": "#f3f3fe",
                  "background": "#faf8ff",
                  "primary": "#004ac6",
                  "surface-container-highest": "#e1e2ed"
          },
          "borderRadius": {
                  "DEFAULT": "0.25rem",
                  "lg": "0.5rem",
                  "xl": "0.75rem",
                  "full": "9999px"
          },
          "spacing": {
                  "container-padding": "20px",
                  "inline-gutter": "12px",
                  "stack-gap": "16px",
                  "section-gap": "24px"
          },
          "fontFamily": {
                  "metadata": ["inter"],
                  "h2": ["Sora"],
                  "label-md": ["Sora"],
                  "h3": ["Sora"],
                  "body-lg": ["inter"],
                  "h1": ["Sora"],
                  "body-sm": ["inter"]
          },
          "fontSize": {
                  "metadata": ["12px", {"fontWeight": "500"}],
                  "h2": ["22px", {"lineHeight": "28px", "letterSpacing": "-0.01em", "fontWeight": "600"}],
                  "label-md": ["14px", {"lineHeight": "18px", "fontWeight": "600"}],
                  "h3": ["18px", {"lineHeight": "24px", "fontWeight": "600"}],
                  "body-lg": ["16px", {"lineHeight": "24px", "fontWeight": "400"}],
                  "h1": ["28px", {"lineHeight": "36px", "letterSpacing": "-0.02em", "fontWeight": "700"}],
                  "body-sm": ["14px", {"lineHeight": "20px", "fontWeight": "400"}]
          }
        },
      },
    }
  </script>
<style>
    body { background-color: #F0F4FF; }
    .primary-gradient { background: linear-gradient(135deg, #2563eb 0%, #004ac6 100%); }
    .material-symbols-outlined { font-variation-settings: 'FILL' 0, 'wght' 400, 'GRAD' 0, 'opsz' 24; }
    .glass-card { background: rgba(255, 255, 255, 0.9); backdrop-filter: blur(10px); }
  </style>
</head>
<body class="font-body-lg text-on-surface">
<!-- TopAppBar -->
<header class="bg-white dark:bg-slate-900 border-b border-blue-50/50 dark:border-slate-800 shadow-[0_2px_12px_rgba(37,99,235,0.08)] flex justify-between items-center w-full px-5 h-16 sticky top-0 z-50">
<div class="flex items-center gap-4">
<button class="p-2 hover:bg-blue-50 dark:hover:bg-slate-800 transition-colors rounded-full flex items-center justify-center">
<span class="material-symbols-outlined text-slate-500">arrow_back</span>
</button>
<h1 class="font-['Sora'] font-semibold text-lg text-blue-700 dark:text-blue-500">Create New Batch</h1>
</div>
<div class="flex items-center gap-3">
<span class="material-symbols-outlined text-slate-500 hover:bg-blue-50 dark:hover:bg-slate-800 transition-colors p-2 rounded-full cursor-pointer" data-icon="notifications">notifications</span>
<span class="material-symbols-outlined text-slate-500 hover:bg-blue-50 dark:hover:bg-slate-800 transition-colors p-2 rounded-full cursor-pointer" data-icon="help_outline">help_outline</span>
</div>
</header>
<main class="max-w-6xl mx-auto px-container-padding py-section-gap mb-24">
<!-- Progress Stepper -->
<div class="flex items-center justify-center mb-section-gap">
<div class="flex items-center w-full max-w-2xl">
<div class="flex flex-col items-center flex-1">
<div class="w-8 h-8 rounded-full bg-primary-container text-on-primary-container flex items-center justify-center font-label-md text-label-md mb-2">1</div>
<span class="font-metadata text-metadata text-slate-500">Industry</span>
</div>
<div class="h-[2px] flex-1 bg-primary-container mx-2"></div>
<div class="flex flex-col items-center flex-1">
<div class="w-10 h-10 rounded-full primary-gradient text-white flex items-center justify-center font-label-md text-label-md shadow-lg ring-4 ring-blue-100 mb-2">2</div>
<span class="font-label-md text-label-md text-primary font-bold">Checks &amp; Cost</span>
</div>
<div class="h-[2px] flex-1 bg-slate-200 mx-2"></div>
<div class="flex flex-col items-center flex-1">
<div class="w-8 h-8 rounded-full bg-slate-100 text-slate-400 flex items-center justify-center font-label-md text-label-md mb-2">3</div>
<span class="font-metadata text-metadata text-slate-400">Permissions</span>
</div>
</div>
</div>
<div class="grid grid-cols-1 lg:grid-cols-3 gap-section-gap">
<!-- Selection Column -->
<div class="lg:col-span-2 space-y-stack-gap">
<h2 class="font-h2 text-h2 text-on-surface mb-inline-gutter">Select Verification Checks</h2>
<!-- Checks List -->
<div class="space-y-4">
<!-- Check Item 1 -->
<label class="group flex items-center justify-between p-5 bg-white rounded-xl shadow-[0_2px_12px_rgba(37,99,235,0.08)] border-2 border-transparent hover:border-primary/20 transition-all cursor-pointer">
<div class="flex items-center gap-4">
<input checked="" class="w-6 h-6 rounded border-slate-300 text-primary focus:ring-primary" type="checkbox"/>
<div>
<p class="font-h3 text-h3 text-on-surface">Identity Verification</p>
<div class="flex items-center gap-2 mt-1">
<span class="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold bg-blue-50 text-blue-600 uppercase tracking-wider">API (auto)</span>
<span class="font-metadata text-metadata text-slate-400">KYC/Aadhar Link</span>
</div>
</div>
</div>
<p class="font-h3 text-h3 text-primary">₹120</p>
</label>
<!-- Check Item 2 -->
<label class="group flex items-center justify-between p-5 bg-white rounded-xl shadow-[0_2px_12px_rgba(37,99,235,0.08)] border-2 border-transparent hover:border-primary/20 transition-all cursor-pointer">
<div class="flex items-center gap-4">
<input checked="" class="w-6 h-6 rounded border-slate-300 text-primary focus:ring-primary" type="checkbox"/>
<div>
<p class="font-h3 text-h3 text-on-surface">Address History</p>
<div class="flex items-center gap-2 mt-1">
<span class="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold bg-slate-100 text-slate-500 uppercase tracking-wider">Human (manual)</span>
<span class="font-metadata text-metadata text-slate-400">Physical Check</span>
</div>
</div>
</div>
<p class="font-h3 text-h3 text-primary">₹240</p>
</label>
<!-- Check Item 3 -->
<label class="group flex items-center justify-between p-5 bg-white rounded-xl shadow-[0_2px_12px_rgba(37,99,235,0.08)] border-2 border-transparent hover:border-primary/20 transition-all cursor-pointer">
<div class="flex items-center gap-4">
<input checked="" class="w-6 h-6 rounded border-slate-300 text-primary focus:ring-primary" type="checkbox"/>
<div>
<p class="font-h3 text-h3 text-on-surface">Criminal Record Search</p>
<div class="flex items-center gap-2 mt-1">
<span class="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold bg-blue-50 text-blue-600 uppercase tracking-wider">API (auto)</span>
<span class="font-metadata text-metadata text-slate-400">National Database</span>
</div>
</div>
</div>
<p class="font-h3 text-h3 text-primary">₹185</p>
</label>
<!-- Check Item 4 -->
<label class="group flex items-center justify-between p-5 bg-white rounded-xl shadow-[0_2px_12px_rgba(37,99,235,0.08)] border-2 border-transparent hover:border-primary/20 transition-all cursor-pointer">
<div class="flex items-center gap-4">
<input class="w-6 h-6 rounded border-slate-300 text-primary focus:ring-primary" type="checkbox"/>
<div>
<p class="font-h3 text-h3 text-on-surface">Education Verification</p>
<div class="flex items-center gap-2 mt-1">
<span class="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold bg-slate-100 text-slate-500 uppercase tracking-wider">Human (manual)</span>
<span class="font-metadata text-metadata text-slate-400">Institute Check</span>
</div>
</div>
</div>
<p class="font-h3 text-h3 text-slate-400">₹300</p>
</label>
<!-- Check Item 5 -->
<label class="group flex items-center justify-between p-5 bg-white rounded-xl shadow-[0_2px_12px_rgba(37,99,235,0.08)] border-2 border-transparent hover:border-primary/20 transition-all cursor-pointer">
<div class="flex items-center gap-4">
<input class="w-6 h-6 rounded border-slate-300 text-primary focus:ring-primary" type="checkbox"/>
<div>
<p class="font-h3 text-h3 text-on-surface">Employment History</p>
<div class="flex items-center gap-2 mt-1">
<span class="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold bg-slate-100 text-slate-500 uppercase tracking-wider">Human (manual)</span>
<span class="font-metadata text-metadata text-slate-400">Previous HR Contact</span>
</div>
</div>
</div>
<p class="font-h3 text-h3 text-slate-400">₹450</p>
</label>
</div>
</div>
<!-- Right Column: Summary -->
<div class="lg:col-span-1">
<div class="sticky top-24 bg-white rounded-xl shadow-[0_4px_24px_rgba(37,99,235,0.12)] p-6 border border-blue-50">
<h3 class="font-h3 text-h3 text-on-surface mb-6 flex items-center gap-2">
<span class="material-symbols-outlined text-primary" data-icon="receipt_long">receipt_long</span>
            Cost Summary
          </h3>
<div class="space-y-4 mb-8">
<div class="flex justify-between items-center text-body-sm">
<span class="text-slate-500">Identity Verification</span>
<span class="font-semibold text-on-surface">₹120</span>
</div>
<div class="flex justify-between items-center text-body-sm">
<span class="text-slate-500">Address History</span>
<span class="font-semibold text-on-surface">₹240</span>
</div>
<div class="flex justify-between items-center text-body-sm">
<span class="text-slate-500">Criminal Record</span>
<span class="font-semibold text-on-surface">₹185</span>
</div>
<div class="pt-4 border-t border-slate-100 flex justify-between items-end">
<div>
<p class="font-metadata text-metadata text-slate-400 uppercase tracking-tighter">Total Per Unit</p>
<p class="font-h1 text-h1 text-primary">₹545</p>
</div>
<div class="bg-blue-50 px-3 py-1 rounded-lg text-blue-600 font-label-md text-[12px]">
                3 Checks
              </div>
</div>
</div>
<div class="p-4 bg-blue-50/50 rounded-xl border border-blue-100 mb-8">
<label class="flex items-start gap-3 cursor-pointer">
<input class="mt-1 w-5 h-5 rounded border-blue-300 text-primary focus:ring-primary" type="checkbox"/>
<span class="font-body-sm text-body-sm text-slate-600">I agree to the per-unit cost breakdown and the terms of service for these verification checks.</span>
</label>
</div>
<button class="w-full h-[54px] primary-gradient rounded-xl text-white font-label-md text-label-md shadow-lg shadow-blue-200 hover:opacity-90 transition-opacity flex items-center justify-center gap-2">
            Continue
            <span class="material-symbols-outlined" data-icon="arrow_forward">arrow_forward</span>
</button>
</div>
</div>
</div>
</main>
<!-- Visual Anchor Element (Hero Image) -->
<div class="fixed bottom-0 right-0 -z-10 opacity-10 pointer-events-none">
<img alt="" class="w-[600px] grayscale" data-alt="A highly professional and secure abstract digital background featuring complex network patterns and data verification nodes. The lighting is low-key with subtle blue highlights, creating a sense of deep technical security and institutional trust. The visual style is clean and modern, perfectly aligning with a high-end corporate identity management platform's aesthetic." src="https://lh3.googleusercontent.com/aida-public/AB6AXuA3hZjG0z2v8V6RDoslHkeB-Pq-jd6sIaNEvssfK_eWWEPkwpsKuVnul1ZDwi5qFSXpETpXemxVdUNrmSwn02_2fEi8we0Crcg0LWsT2bcSMQGisudxfFxZpezMVfPTxvdMQw3lvPUmfUqDoWx3A-e10yreSPKZ3_0NtN8wgIuVMv7JJ-74CIqoPY7760_dMMccZogvhmM2vPWLQCVBa7QYDMuF0uJ7rIAMDvszZsVgm8S95cWJLTw9aB1YJLDi3Dos28hXTH0Nd18"/>
</div>
<!-- Bottom Navigation (Mobile Only) -->
<nav class="md:hidden bg-white/95 dark:bg-slate-900/95 backdrop-blur-md border-t border-slate-100 dark:border-slate-800 shadow-[0_-4px_16px_rgba(37,99,235,0.04)] fixed bottom-0 left-0 w-full h-[64px] flex justify-around items-center px-4 pb-safe z-50">
<a class="flex flex-col items-center justify-center text-blue-600 dark:text-blue-400 after:content-[''] after:w-1 after:h-1 after:bg-blue-600 after:rounded-full after:mt-1" href="#">
<span class="material-symbols-outlined" data-icon="list_alt">list_alt</span>
<span class="font-['Sora'] text-[10px] font-medium uppercase">Batches</span>
</a>
<a class="flex flex-col items-center justify-center text-slate-400 dark:text-slate-500" href="#">
<span class="material-symbols-outlined" data-icon="verified_user">verified_user</span>
<span class="font-['Sora'] text-[10px] font-medium uppercase">Verification</span>
</a>
<a class="flex flex-col items-center justify-center text-slate-400 dark:text-slate-500" href="#">
<span class="material-symbols-outlined" data-icon="folder_shared">folder_shared</span>
<span class="font-['Sora'] text-[10px] font-medium uppercase">Directory</span>
</a>
<a class="flex flex-col items-center justify-center text-slate-400 dark:text-slate-500" href="#">
<span class="material-symbols-outlined" data-icon="settings">settings</span>
<span class="font-['Sora'] text-[10px] font-medium uppercase">Settings</span>
</a>
</nav>
</body></html>





Dashboard → New Batch
        ↓
  Select Industry
  (Transport, Healthcare, Education, Manufacturing, Security, Agriculture, Products, Others)
        ↓
  Select Verification Checks
  (tick which checks needed — each labelled API-auto or Human-manual)
  Examples:
    • Identity      → API (auto)
    • Address       → Manual
    • Police Clear  → Manual
    • Education     → API (NAD)
    • Employment    → API (EPFO)
    • Criminal      → Manual
    • Product Comp  → Manual
        ↓
  Per-Unit Cost Breakdown shown
  (₹X per check per person — org agrees before proceeding)
        ↓
  Permission Setting
  (Public searchable OR Permission-based with WhatsApp/email consent)