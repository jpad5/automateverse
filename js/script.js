// ===================================================================
// AutomateVerse LLC — Site Interactions
// ===================================================================

(() => {
    'use strict';

    // ===== Mobile Menu =====
    const mobileMenu = document.getElementById('mobile-menu');
    const navMenu = document.querySelector('.nav-menu');

    if (mobileMenu) {
        mobileMenu.addEventListener('click', () => {
            mobileMenu.classList.toggle('active');
            navMenu.classList.toggle('active');
        });
    }

    // ===== Smooth Scrolling =====
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                const navHeight = document.querySelector('.navbar').offsetHeight;
                const targetPos = target.getBoundingClientRect().top + window.scrollY - navHeight;
                window.scrollTo({ top: targetPos, behavior: 'smooth' });

                // Close mobile menu
                if (navMenu && navMenu.classList.contains('active')) {
                    mobileMenu.classList.remove('active');
                    navMenu.classList.remove('active');
                }
            }
        });
    });

    // Close mobile menu on outside click
    document.addEventListener('click', (e) => {
        if (mobileMenu && navMenu &&
            !mobileMenu.contains(e.target) &&
            !navMenu.contains(e.target)) {
            mobileMenu.classList.remove('active');
            navMenu.classList.remove('active');
        }
    });

    // ===== Navbar Scroll Effect =====
    const navbar = document.querySelector('.navbar');
    let lastScrollY = 0;

    window.addEventListener('scroll', () => {
        if (window.scrollY > 50) {
            navbar.classList.add('scrolled');
        } else {
            navbar.classList.remove('scrolled');
        }
        lastScrollY = window.scrollY;
    }, { passive: true });

    // ===== Active Nav Link Tracking =====
    const sections = document.querySelectorAll('section[id]');
    const navLinks = document.querySelectorAll('.nav-link');

    function updateActiveNav() {
        const scrollPos = window.scrollY + 100;

        sections.forEach(section => {
            const top = section.offsetTop - 100;
            const bottom = top + section.offsetHeight;
            const id = section.getAttribute('id');

            if (scrollPos >= top && scrollPos < bottom) {
                navLinks.forEach(link => {
                    link.classList.remove('active');
                    if (link.getAttribute('href') === `#${id}`) {
                        link.classList.add('active');
                    }
                });
            }
        });
    }

    window.addEventListener('scroll', updateActiveNav, { passive: true });

    // ===== Scroll-Triggered Animations =====
    const animationObserver = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('visible');
                animationObserver.unobserve(entry.target);
            }
        });
    }, {
        threshold: 0.1,
        rootMargin: '0px 0px -60px 0px'
    });

    function initAnimations() {
        // Cards and grid items get staggered animations
        const animatableGroups = [
            '.about-card',
            '.service-card',
            '.process-step',
            '.industry-card',
            '.why-card',
            '.contact-card'
        ];

        animatableGroups.forEach(selector => {
            const elements = document.querySelectorAll(selector);
            elements.forEach((el, index) => {
                el.classList.add('animate-on-scroll');
                el.style.transitionDelay = `${index * 0.1}s`;
                animationObserver.observe(el);
            });
        });

        // Section headings, labels, subtitles
        document.querySelectorAll('.section-label, .section h2, .section-subtitle').forEach(el => {
            el.classList.add('animate-on-scroll');
            animationObserver.observe(el);
        });
    }

    // ===== Hero Title Typewriter =====
    function initHeroAnimation() {
        const heroTitle = document.querySelector('.hero-content h1');
        const heroBadge = document.querySelector('.hero-badge');
        const heroP = document.querySelector('.hero-content p');
        const heroCta = document.querySelector('.hero-cta-group');

        if (heroBadge) {
            heroBadge.style.opacity = '0';
            heroBadge.style.transform = 'translateY(20px)';
            setTimeout(() => {
                heroBadge.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
                heroBadge.style.opacity = '1';
                heroBadge.style.transform = 'translateY(0)';
            }, 200);
        }

        if (heroTitle) {
            heroTitle.style.opacity = '0';
            heroTitle.style.transform = 'translateY(30px)';
            setTimeout(() => {
                heroTitle.style.transition = 'opacity 0.7s ease, transform 0.7s ease';
                heroTitle.style.opacity = '1';
                heroTitle.style.transform = 'translateY(0)';
            }, 400);
        }

        if (heroP) {
            heroP.style.opacity = '0';
            heroP.style.transform = 'translateY(20px)';
            setTimeout(() => {
                heroP.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
                heroP.style.opacity = '1';
                heroP.style.transform = 'translateY(0)';
            }, 700);
        }

        if (heroCta) {
            heroCta.style.opacity = '0';
            heroCta.style.transform = 'translateY(20px)';
            setTimeout(() => {
                heroCta.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
                heroCta.style.opacity = '1';
                heroCta.style.transform = 'translateY(0)';
            }, 900);
        }
    }

    // ===== Init on DOM Ready =====
    document.addEventListener('DOMContentLoaded', () => {
        initHeroAnimation();
        initAnimations();
        updateActiveNav();
    });
})();

// Add contact form functionality (if a contact form is added later)
function handleContactForm(event) {
    event.preventDefault();
    // Form handling logic would go here
    alert('Thank you for your message! We\'ll get back to you soon.');
}