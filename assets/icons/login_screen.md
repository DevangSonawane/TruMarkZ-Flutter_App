<!DOCTYPE html>

<html class="light" lang="en"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<title>TruMarkZ Login</title>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<link href="https://fonts.googleapis.com/css2?family=Manrope:wght@400;600;700;800&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<script id="tailwind-config">
        tailwind.config = {
            darkMode: "class",
            theme: {
                extend: {
                    "colors": {
                        "tertiary": "#994200",
                        "on-surface-variant": "#424754",
                        "inverse-surface": "#2f3133",
                        "secondary": "#565f6b",
                        "surface-container-high": "#e8e8ea",
                        "on-error": "#ffffff",
                        "secondary-container": "#dae3f1",
                        "inverse-primary": "#afc6ff",
                        "on-primary-container": "#fefcff",
                        "primary-container": "#0f6ef0",
                        "error-container": "#ffdad6",
                        "tertiary-fixed": "#ffdbca",
                        "outline-variant": "#c2c6d7",
                        "error": "#ba1a1a",
                        "primary-fixed": "#d9e2ff",
                        "secondary-fixed": "#dae3f1",
                        "on-error-container": "#93000a",
                        "outline": "#727786",
                        "surface-tint": "#0059c7",
                        "surface-dim": "#dadadc",
                        "surface-container": "#eeeef0",
                        "on-tertiary-container": "#fffbff",
                        "surface": "#f9f9fc",
                        "surface-container-highest": "#e2e2e5",
                        "primary-fixed-dim": "#afc6ff",
                        "secondary-fixed-dim": "#bec7d5",
                        "on-background": "#1a1c1e",
                        "surface-container-lowest": "#ffffff",
                        "tertiary-container": "#c05400",
                        "on-secondary-fixed": "#131c26",
                        "background": "#f9f9fc",
                        "on-secondary": "#ffffff",
                        "on-tertiary-fixed-variant": "#773200",
                        "on-primary-fixed": "#001944",
                        "on-surface": "#1a1c1e",
                        "inverse-on-surface": "#f0f0f3",
                        "on-tertiary-fixed": "#331100",
                        "surface-bright": "#f9f9fc",
                        "tertiary-fixed-dim": "#ffb68f",
                        "surface-variant": "#e2e2e5",
                        "on-primary": "#ffffff",
                        "on-tertiary": "#ffffff",
                        "primary": "#0057c3",
                        "surface-container-low": "#f3f3f6",
                        "on-secondary-fixed-variant": "#3f4853",
                        "on-secondary-container": "#5c6571",
                        "on-primary-fixed-variant": "#004299"
                    },
                    "borderRadius": {
                        "DEFAULT": "0.25rem",
                        "lg": "24px",
                        "xl": "32px",
                        "full": "9999px"
                    },
                    "spacing": {
                        "lg": "24px",
                        "xxl": "48px",
                        "xl": "32px",
                        "md": "16px",
                        "xs": "4px",
                        "container-padding": "20px",
                        "sm": "8px",
                        "card-gap": "16px"
                    },
                    "fontFamily": {
                        "headline-lg-mobile": ["Manrope"],
                        "body-md": ["Manrope"],
                        "label-md": ["Manrope"],
                        "body-lg": ["Manrope"],
                        "headline-md": ["Manrope"],
                        "headline-sm": ["Manrope"],
                        "headline-lg": ["Manrope"]
                    },
                    "fontSize": {
                        "headline-lg-mobile": ["24px", {"lineHeight": "32px", "fontWeight": "700"}],
                        "body-md": ["14px", {"lineHeight": "20px", "fontWeight": "400"}],
                        "label-md": ["12px", {"lineHeight": "16px", "letterSpacing": "0.01em", "fontWeight": "600"}],
                        "body-lg": ["16px", {"lineHeight": "24px", "fontWeight": "400"}],
                        "headline-md": ["22px", {"lineHeight": "28px", "letterSpacing": "-0.01em", "fontWeight": "700"}],
                        "headline-sm": ["18px", {"lineHeight": "24px", "fontWeight": "600"}],
                        "headline-lg": ["28px", {"lineHeight": "36px", "letterSpacing": "-0.02em", "fontWeight": "700"}]
                    }
                },
            },
        }
    </script>
<style>
        .material-symbols-outlined {
            font-variation-settings: 'FILL' 0, 'wght' 400, 'GRAD' 0, 'opsz' 24;
        }
        .card-shadow {
            box-shadow: 0px 8px 24px rgba(0, 0, 0, 0.04);
        }
        body {
            font-family: 'Manrope', sans-serif;
            background-color: #f9f9fc;
        }
    </style>
<style>
    body {
      min-height: max(884px, 100dvh);
    }
  </style>
  </head>
<body class="bg-background text-on-surface min-h-screen flex flex-col items-center">
<!-- TopAppBar -->
<header class="flex justify-center items-center py-lg px-lg w-full bg-transparent docked full-width top-0">
<div class="flex flex-col items-center gap-xs">
<div class="w-12 h-12 bg-primary-container rounded-full flex items-center justify-center mb-xs">
<span class="material-symbols-outlined text-on-primary-container" style="font-size: 28px;">fingerprint</span>
</div>
<h1 class="font-headline-md text-headline-md-mobile font-bold text-primary">TruMarkZ</h1>
<p class="font-label-md text-label-md text-on-surface-variant tracking-widest uppercase">THE STANDARD IN DIGITAL VERIFICATION</p>
</div>
</header>
<main class="flex-grow flex flex-col items-center justify-center w-full px-lg max-w-[480px] py-xxl">
<!-- Auth Card -->
<div class="bg-surface-container-lowest w-full rounded-lg p-lg card-shadow flex flex-col gap-xl">
<!-- Welcome Header -->
<div class="flex flex-col gap-xs text-center">
<h2 class="font-headline-lg-mobile text-headline-lg-mobile text-on-surface">Welcome Back</h2>
<p class="font-body-md text-body-md text-on-surface-variant">Sign in to your account</p>
</div>
<!-- Login Form -->
<form class="flex flex-col gap-md">
<div class="flex flex-col gap-sm">
<label class="font-label-md text-label-md text-on-surface-variant ml-sm">Email</label>
<div class="relative flex items-center">
<span class="material-symbols-outlined absolute left-4 text-outline" data-icon="mail">mail</span>
<input class="w-full h-[56px] pl-12 pr-4 bg-surface-container rounded-lg border-none focus:ring-2 focus:ring-primary font-body-md text-on-surface placeholder:text-outline-variant" placeholder="example@trumarkz.com" type="email"/>
</div>
</div>
<div class="flex flex-col gap-sm">
<label class="font-label-md text-label-md text-on-surface-variant ml-sm">Password</label>
<div class="relative flex items-center">
<span class="material-symbols-outlined absolute left-4 text-outline" data-icon="lock">lock</span>
<input class="w-full h-[56px] pl-12 pr-12 bg-surface-container rounded-lg border-none focus:ring-2 focus:ring-primary font-body-md text-on-surface placeholder:text-outline-variant" placeholder="••••••••" type="password"/>
<span class="material-symbols-outlined absolute right-4 text-outline cursor-pointer" data-icon="visibility">visibility</span>
</div>
</div>
<div class="flex justify-end">
<a class="font-label-md text-label-md text-primary font-bold hover:opacity-80 transition-opacity" href="#">Forgot Password?</a>
</div>
<button class="w-full h-[56px] bg-primary text-on-primary font-headline-sm text-headline-sm rounded-lg hover:opacity-90 transition-opacity mt-md shadow-md" type="submit">
                    Sign In
                </button>
</form>
<!-- Social Divider -->
<div class="flex items-center gap-md">
<div class="h-[1px] flex-grow bg-surface-variant"></div>
<span class="font-label-md text-label-md text-on-surface-variant">or continue with</span>
<div class="h-[1px] flex-grow bg-surface-variant"></div>
</div>
<!-- Social Auth -->
<button class="w-full h-[56px] border border-outline-variant rounded-lg flex items-center justify-center gap-md hover:bg-surface-container transition-colors group">
<img alt="Google" class="w-6 h-6 grayscale group-hover:grayscale-0 transition-all" data-alt="A clean, isolated Google 'G' logo on a transparent background, rendered in high resolution with its iconic primary colors of blue, red, yellow, and green. The lighting is neutral and the style is modern corporate flat design, suitable for a professional identity verification interface in light mode." src="https://lh3.googleusercontent.com/aida-public/AB6AXuDzVJBT7ZbDodWvqmWtG8VYMbRxqDzynEuC9Lehpkl3Uh33drPIiJ2JmR61eN8zHLZqdnPudS_Ik15H7MiW4i271z5j6HoTNf4PCKyNzFytw8UlO8uSXYjSm6hvi4XjL_rX9NBcTMXwqLXVTtN1VZIviv2hD3Wj5sNrQ4c2msXdaxKxgWjP9OvDbccSE-x3BsHFAavz2ILjHJN9YGloRdkCs_RgGZNxz-xvvNAME41wmCZJlRnkGtfnB2rQj0_x56FfkGZRA1ejzamC"/>
<span class="font-body-lg text-body-lg text-on-surface font-semibold">Sign in with Google</span>
</button>
<!-- Register Link -->
<div class="text-center mt-md">
<p class="font-body-md text-body-md text-on-surface-variant">
                    Don't have an account? 
                    <a class="text-primary font-bold hover:underline" href="#">Register</a>
</p>
</div>
</div>
</main>
<!-- Footer -->
<footer class="w-full flex flex-col items-center gap-sm pb-xl px-lg bg-transparent docked full-width bottom-0">
<div class="flex items-center gap-xs text-on-secondary-fixed-variant opacity-60">
<span class="material-symbols-outlined" data-weight="fill" style="font-variation-settings: 'FILL' 1;">shield</span>
<span class="font-label-md text-label-md uppercase tracking-wider">SECURED BY TRUMARKZ IDENTITY PROTOCOL</span>
</div>
<div class="flex gap-lg mt-sm">
<a class="font-label-md text-label-md text-on-surface-variant hover:text-primary transition-colors" href="#">Terms of Service</a>
<a class="font-label-md text-label-md text-on-surface-variant hover:text-primary transition-colors" href="#">Privacy Policy</a>
</div>
<p class="font-label-md text-label-md text-on-surface-variant mt-sm">Secured by Quantum-Grade Protocol</p>
</footer>
</body></html>