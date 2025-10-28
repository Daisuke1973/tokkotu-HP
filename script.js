document.addEventListener('DOMContentLoaded', function() {
    // Accordion functionality
    const accordionHeaders = document.querySelectorAll('.accordion-header');
    accordionHeaders.forEach(header => {
        if (header.closest('.song-section')) {
            return;
        }
        header.addEventListener('click', (e) => {
            // Ensure any nested interactive elements don't navigate
            e.preventDefault();
            toggleAccordion(header);
        });
    });

    // Inline max-height control is disabled; rely on CSS class for expansion

    function toggleAccordion(header, open) {
        const accordionItem = header.parentElement;
        const accordionContent = header.nextElementSibling;
        if (!accordionItem || !accordionContent) return;

        const isActive = header.classList.contains('active');

        const openSection = () => {
            // Add classes first (preferred CSS-driven expand)
            accordionItem.classList.add('active');
            header.classList.add('active');

            // Fallback: if for any reason the section doesn't expand,
            // set an inline max-height to the current content height to ensure opening,
            // then clean it up after the transition so CSS can take over.
            const computed = getComputedStyle(accordionContent);
            const currentlyZero = computed.maxHeight === '0px' || accordionContent.offsetHeight === 0;
            if (currentlyZero) {
                accordionContent.style.maxHeight = accordionContent.scrollHeight + 'px';
                const cleanup = () => {
                    accordionContent.style.maxHeight = null;
                    accordionContent.removeEventListener('transitionend', cleanup);
                };
                accordionContent.addEventListener('transitionend', cleanup);
            } else {
                // Ensure no stale inline value remains
                accordionContent.style.maxHeight = null;
            }
        };

        const closeSection = () => {
            // Animate close robustly: set explicit height, then collapse
            const startHeight = accordionContent.scrollHeight;
            accordionContent.style.maxHeight = startHeight + 'px';
            // Force reflow to apply the starting height
            void accordionContent.offsetHeight;

            header.classList.remove('active');
            accordionItem.classList.remove('active');

            accordionContent.style.maxHeight = '0px';

            const cleanup = () => {
                accordionContent.style.maxHeight = null;
                accordionContent.removeEventListener('transitionend', cleanup);
            };
            accordionContent.addEventListener('transitionend', cleanup);
        };

        if (open === true && !isActive) {
            openSection();
        } else if (open === false && isActive) {
            closeSection();
        } else if (open === undefined) {
            if (isActive) {
                closeSection();
            } else {
                openSection();
            }
        }
    }

    // Image Modal functionality + broken image fallback
    const modal = document.getElementById("imageModal");
    const modalImg = document.getElementById("img01");
    const images = document.querySelectorAll('.image-grid img, .image-gallery img');
    const closeBtn = document.querySelector(".modal .close");

    // Track the element that opened the modal for focus restoration
    let modalTriggerElement = null;

    // Focusable elements for focus trap
    const getFocusableElements = () => {
        if (!modal) return [];
        return Array.from(modal.querySelectorAll(
            'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
        )).filter(el => !el.hasAttribute('disabled'));
    };

    // Focus trap for modal
    const handleModalKeydown = (e) => {
        if (e.key === 'Escape') {
            closeModal();
            return;
        }

        if (e.key === 'Tab') {
            const focusableElements = getFocusableElements();
            if (focusableElements.length === 0) return;

            const firstElement = focusableElements[0];
            const lastElement = focusableElements[focusableElements.length - 1];

            if (e.shiftKey && document.activeElement === firstElement) {
                e.preventDefault();
                lastElement.focus();
            } else if (!e.shiftKey && document.activeElement === lastElement) {
                e.preventDefault();
                firstElement.focus();
            }
        }
    };

    // Open modal function
    const openModal = (src, triggerElement) => {
        if (!modal || !modalImg) return;
        modalTriggerElement = triggerElement;
        modalImg.src = src;
        modal.style.display = "block";
        if (modal.setAttribute) modal.setAttribute('aria-hidden', 'false');

        // Focus the close button when modal opens
        if (closeBtn) {
            setTimeout(() => closeBtn.focus(), 100);
        }

        // Add keyboard event listener
        document.addEventListener('keydown', handleModalKeydown);
    };

    // Close modal function
    const closeModal = () => {
        if (!modal) return;
        modal.style.display = "none";
        if (modal.setAttribute) modal.setAttribute('aria-hidden', 'true');

        // Remove keyboard event listener
        document.removeEventListener('keydown', handleModalKeydown);

        // Restore focus to the element that opened the modal
        if (modalTriggerElement) {
            modalTriggerElement.focus();
            modalTriggerElement = null;
        }
    };

    // Track broken images per container to optionally show a placeholder text
    const containerStats = new Map();
    const getStat = (container) => {
        if (!containerStats.has(container)) {
            containerStats.set(container, { total: 0, error: 0, shownPlaceholder: false });
        }
        return containerStats.get(container);
    };

    images.forEach(img => {
        const container = img.closest('.image-grid, .image-gallery');
        if (container) getStat(container).total++;

        img.addEventListener('error', () => {
            // Hide broken image
            img.style.display = 'none';
            if (container) {
                const stat = getStat(container);
                stat.error++;
                if (!stat.shownPlaceholder && stat.error >= stat.total) {
                    stat.shownPlaceholder = true;
                    const note = document.createElement('div');
                    note.textContent = '写真は準備中です';
                    note.style.padding = '12px 0';
                    note.style.color = '#666';
                    note.style.fontSize = '0.95em';
                    container.appendChild(note);
                }
            }
        });

        // When images load inside an open accordion, no inline height adjustments needed
        img.addEventListener('load', () => {
            // No-op: CSS active state uses a large max-height to avoid clipping
        });

        // Prefer opening the modal over following <a> navigation
        img.addEventListener('click', (e) => {
            if (!modal || !modalImg) return;
            e.preventDefault();
            e.stopPropagation();

            // If the image is wrapped by <a>, use its href (full-size) when present
            const anchor = img.closest('a');
            const targetSrc = (anchor && anchor.getAttribute('href')) ? anchor.getAttribute('href') : img.getAttribute('src');

            openModal(targetSrc, img);
        });
    });

    if(closeBtn) {
        closeBtn.onclick = function() {
            closeModal();
        }
    }

    window.onclick = function(event) {
        if (event.target == modal) {
            closeModal();
        }
    }

    // Song lyrics toggle
    const songHeaders = document.querySelectorAll('.song-section h3');
    songHeaders.forEach(header => {
        header.addEventListener('click', function() {
            this.classList.toggle('active');
            const content = this.nextElementSibling;
            if (content.style.maxHeight && content.style.maxHeight !== '0px'){
                content.style.maxHeight = '0px';
                content.style.padding = '0 20px';
                content.style.opacity = '0';
            } else {
                content.style.padding = '20px';
                content.style.opacity = '1';
                content.style.maxHeight = content.scrollHeight + "px";
            }
        });
    });

    // Back to top button functionality
    const backToTopButton = document.getElementById('back-to-top');

    if (backToTopButton) {
        window.addEventListener('scroll', () => {
            if (window.pageYOffset > 300) { // Show button after scrolling 300px
                backToTopButton.style.display = 'block';
            } else {
                backToTopButton.style.display = 'none';
            }
        });

        backToTopButton.addEventListener('click', (e) => {
            e.preventDefault();
            window.scrollTo({ top: 0, behavior: 'smooth' });
        });
    }

    // TOC Dropdown functionality
    const tocToggleBtn = document.getElementById('toc-toggle-btn');
    const tocContent = document.getElementById('toc-content');

    if (tocToggleBtn && tocContent) {
        tocToggleBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            tocToggleBtn.classList.toggle('active');
            tocContent.classList.toggle('show');
            if (tocContent.classList.contains('show')) {
                tocContent.style.maxHeight = tocContent.scrollHeight + "px";
            } else {
                tocContent.style.maxHeight = null;
            }
        });

        document.addEventListener('click', (event) => {
            if (!tocToggleBtn.contains(event.target) && !tocContent.contains(event.target)) {
                if (tocContent.classList.contains('show')) {
                    tocToggleBtn.classList.remove('active');
                    tocContent.classList.remove('show');
                    tocContent.style.maxHeight = null;
                }
            }
        });

        const tocLinks = tocContent.querySelectorAll('a');
        tocLinks.forEach(link => {
            link.addEventListener('click', function(e) {
                e.preventDefault();
                const targetId = this.getAttribute('href').substring(1);
                const targetElement = document.getElementById(targetId);

                if (targetElement) {
                    const targetHeader = targetElement.querySelector('.accordion-header');
                    const accordionContent = targetHeader.nextElementSibling;

                    const scrollToTarget = () => {
                        const nav = document.querySelector('nav');
                        const navHeight = nav ? nav.offsetHeight : 0;
                        const targetPosition = targetElement.getBoundingClientRect().top + window.pageYOffset - navHeight - 20; // 20px offset for padding

                        window.scrollTo({
                            top: targetPosition,
                            behavior: 'smooth'
                        });
                    };

                    // Close the dropdown menu first
                    tocToggleBtn.classList.remove('active');
                    tocContent.classList.remove('show');
                    tocContent.style.maxHeight = null;

                    if (!targetHeader.classList.contains('active')) {
                        // Listen for the transition to end, then scroll
                        accordionContent.addEventListener('transitionend', scrollToTarget, { once: true });
                        toggleAccordion(targetHeader, true);
                    } else {
                        // If already open, just scroll
                        scrollToTarget();
                    }
                }
            });
        });
    }

    // No resize recalculation necessary when using CSS-only large max-height

    // Enhanced search/filter for pages that have #searchInput (e.g., yakuinkai2.html)
    const searchInput = document.getElementById('searchInput');
    if (searchInput) {
        const accordionItems = Array.from(document.querySelectorAll('.accordion-item'));
        const norm = (s) => (s || '')
            .toString()
            .normalize('NFKC')
            .toLowerCase();

        const textOf = (el) => (el && el.textContent) ? el.textContent.replace(/\s+/g, ' ') : '';

        // Result info element
        let resultInfo = document.getElementById('search-result-info');
        if (!resultInfo) {
            resultInfo = document.createElement('div');
            resultInfo.id = 'search-result-info';
            resultInfo.style.margin = '8px 0 0';
            resultInfo.style.fontSize = '0.9em';
            const container = searchInput.closest('.search-container') || searchInput.parentElement;
            container && container.appendChild(resultInfo);
        }

        const scrollToElement = (el) => {
            if (!el) return;
            const nav = document.querySelector('nav');
            const navHeight = nav ? nav.offsetHeight : 0;
            const y = el.getBoundingClientRect().top + window.pageYOffset - navHeight - 16;
            window.scrollTo({ top: y, behavior: 'smooth' });
        };

        const applyFilter = (q, opts = {}) => {
            const qn = norm(q.trim());
            let visibleCount = 0;
            let firstMatch = null;

            accordionItems.forEach((item) => {
                const header = item.querySelector('.accordion-header');
                const hay = norm(textOf(item));
                const match = qn === '' || hay.includes(qn);
                item.style.display = match ? '' : 'none';

                // Open/close sections to make results obvious
                if (header) {
                    if (qn === '') {
                        // Keep current state when query cleared
                    } else if (match) {
                        toggleAccordion(header, true);
                        if (!firstMatch) firstMatch = header;
                    } else {
                        toggleAccordion(header, false);
                    }
                }

                if (match) visibleCount++;
            });

            // Result info text
            if (resultInfo) {
                if (qn === '') {
                    resultInfo.textContent = '';
                } else if (visibleCount === 0) {
                    resultInfo.textContent = '該当なし';
                } else {
                    resultInfo.textContent = `${visibleCount}件ヒット`;
                }
            }

            // Optional scroll to first match
            if (opts.scroll && firstMatch) {
                scrollToElement(firstMatch);
            }
        };

        let timer = null;
        searchInput.addEventListener('input', (e) => {
            if (timer) clearTimeout(timer);
            const val = e.target.value;
            timer = setTimeout(() => applyFilter(val, { scroll: true }), 150);
        });

        searchInput.addEventListener('keydown', (e) => {
            if (e.key === 'Enter') {
                e.preventDefault();
                applyFilter(searchInput.value, { scroll: true });
            }
        });
    }
});
