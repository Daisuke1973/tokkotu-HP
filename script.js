document.addEventListener('DOMContentLoaded', function() {
    // Mobile menu toggle
    const mobileMenuToggle = document.querySelector('.mobile-menu-toggle');
    const nav = document.querySelector('nav');

    if (mobileMenuToggle && nav) {
        mobileMenuToggle.addEventListener('click', function() {
            const isOpen = this.classList.toggle('active');
            nav.classList.toggle('mobile-menu-open');
            this.setAttribute('aria-expanded', isOpen);
            this.setAttribute('aria-label', isOpen ? 'メニューを閉じる' : 'メニューを開く');
        });

        // Close menu when clicking on a nav link
        const navLinks = nav.querySelectorAll('a');
        navLinks.forEach(link => {
            link.addEventListener('click', function() {
                mobileMenuToggle.classList.remove('active');
                nav.classList.remove('mobile-menu-open');
                mobileMenuToggle.setAttribute('aria-expanded', 'false');
                mobileMenuToggle.setAttribute('aria-label', 'メニューを開く');
            });
        });
    }

    // Accordion functionality
    const accordionHeaders = document.querySelectorAll('.accordion-header');
    accordionHeaders.forEach(header => {
        // Skip song-section here; it has its own handler below
        if (header.closest('.song-section')) return;
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

    // (removed earlier duplicate song-section handler; unified below)

    // Image Modal functionality + broken image fallback
    const modal = document.getElementById("imageModal");
    const modalImg = document.getElementById("img01");
    const images = document.querySelectorAll('.image-grid img, .image-gallery img');
    const closeBtn = document.querySelector(".modal .close");
    const prevBtn = document.querySelector(".modal-prev");
    const nextBtn = document.querySelector(".modal-next");
    const modalCounter = document.getElementById("modal-counter");

    // Track the element that opened the modal for focus restoration
    let modalTriggerElement = null;

    // Track current image index and current image group for navigation
    let currentImageIndex = 0;
    let currentImageGroup = [];

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

        // Arrow key navigation
        if (e.key === 'ArrowLeft') {
            e.preventDefault();
            navigateImage(-1);
            return;
        }
        if (e.key === 'ArrowRight') {
            e.preventDefault();
            navigateImage(1);
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

    // Navigate to previous/next image
    const navigateImage = (direction) => {
        if (currentImageGroup.length <= 1) return;

        currentImageIndex += direction;

        // Loop around
        if (currentImageIndex < 0) {
            currentImageIndex = currentImageGroup.length - 1;
        } else if (currentImageIndex >= currentImageGroup.length) {
            currentImageIndex = 0;
        }

        const targetImg = currentImageGroup[currentImageIndex];
        const anchor = targetImg.closest('a');
        const targetSrc = (anchor && anchor.getAttribute('href')) ? anchor.getAttribute('href') : targetImg.getAttribute('src');

        modalImg.src = targetSrc;
        modalTriggerElement = targetImg;
        updateCounter();
    };

    // Update modal counter display
    const updateCounter = () => {
        if (modalCounter && currentImageGroup.length > 1) {
            modalCounter.textContent = `${currentImageIndex + 1} / ${currentImageGroup.length}`;
            modalCounter.style.display = 'block';
        } else if (modalCounter) {
            modalCounter.style.display = 'none';
        }
    };

    // Update navigation button visibility
    const updateNavButtons = () => {
        if (prevBtn) prevBtn.style.display = currentImageGroup.length > 1 ? 'block' : 'none';
        if (nextBtn) nextBtn.style.display = currentImageGroup.length > 1 ? 'block' : 'none';
    };

    // Open modal function
    const openModal = (src, triggerElement) => {
        if (!modal || !modalImg) return;
        modalTriggerElement = triggerElement;
        modalImg.src = src;

        // Find the image group (all images in the same container)
        const container = triggerElement.closest('.image-grid, .image-gallery');
        if (container) {
            currentImageGroup = Array.from(container.querySelectorAll('img')).filter(img => img.style.display !== 'none');
            currentImageIndex = currentImageGroup.indexOf(triggerElement);
            if (currentImageIndex === -1) currentImageIndex = 0;
        } else {
            currentImageGroup = [triggerElement];
            currentImageIndex = 0;
        }

        modal.style.display = "block";
        if (modal.setAttribute) modal.setAttribute('aria-hidden', 'false');

        updateCounter();
        updateNavButtons();

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

    // Navigation button handlers
    if (prevBtn) {
        prevBtn.onclick = function(e) {
            e.stopPropagation();
            navigateImage(-1);
        }
    }

    if (nextBtn) {
        nextBtn.onclick = function(e) {
            e.stopPropagation();
            navigateImage(1);
        }
    }

    window.onclick = function(event) {
        if (event.target == modal) {
            closeModal();
        }
    }

    // Song audio helpers
    let currentSongAudio = null;
    let currentSongSection = null;
    function resolveSongAudioSrc(sectionEl, headerEl) {
        const explicit = (sectionEl && sectionEl.dataset && sectionEl.dataset.audio) || (headerEl && headerEl.dataset && headerEl.dataset.audio);
        if (explicit) return explicit;
        const title = (headerEl && headerEl.textContent ? headerEl.textContent : '').trim();

        // Heuristic mappings by header text
        const rules = [
            { includes: ['旭川中', '校歌'], src: 'music/旭中校歌.m4a' },
            { includes: ['旭川東', '校歌'], src: 'music/旭川東高校歌.m4a' },
            { includes: ['旭川東', '逍遥歌'], src: 'music/旭川東高校逍遥歌.mp3' },
            { includes: ['応援歌'], src: 'music/応援歌.m4a' },
        ];
        for (const r of rules) {
            if (r.includes.every(key => title.includes(key))) return r.src;
        }
        return null;
    }
    function pauseCurrentSong() {
        if (currentSongAudio) { try { currentSongAudio.pause(); } catch(_){} }
        currentSongAudio = null;
        currentSongSection = null;
    }
    function playSectionAudio(sectionEl, headerEl) {
        const src = resolveSongAudioSrc(sectionEl, headerEl);
        if (!src) return;
        if (currentSongSection && currentSongSection !== sectionEl) pauseCurrentSong();
        let audio = sectionEl.__songAudio;
        if (!audio) {
            audio = new Audio(src);
            audio.preload = 'none';
            sectionEl.__songAudio = audio;
        } else if (audio.src && !audio.src.endsWith(src)) {
            try { audio.pause(); } catch(_){ }
            audio.src = src;
        }
        currentSongAudio = audio;
        currentSongSection = sectionEl;
        try { audio.currentTime = 0; audio.play().catch(()=>{}); } catch(_){ }
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
                // Pause audio when closing
                const section = this.closest('.song-section');
                if (currentSongSection === section) pauseCurrentSong();
            } else {
                content.style.padding = '20px';
                content.style.opacity = '1';
                content.style.maxHeight = content.scrollHeight + "px";
                // Play audio when opening
                const section = this.closest('.song-section');
                playSectionAudio(section, this);
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

    // Kaihou list search/filter/sort (kaihou-list.html)
    const kaihouTable = document.querySelector('.kaihou-list-table');
    if (kaihouTable) {
        const searchField = document.getElementById('kaihou-search');
        const issueSelect = document.getElementById('kaihou-issue');
        const yearSelect = document.getElementById('kaihou-year');
        const categorySelect = document.getElementById('kaihou-category');
        const sortSelect = document.getElementById('kaihou-sort');
        const resetButton = document.getElementById('kaihou-reset');
        const resultInfo = document.getElementById('kaihou-result-info');
        const tbody = kaihouTable.querySelector('tbody');
        const rows = Array.from(tbody.querySelectorAll('tr'));

        const norm = (s) => (s || '')
            .toString()
            .normalize('NFKC')
            .toLowerCase();
        const getText = (cell) => (cell && cell.textContent ? cell.textContent.trim() : '');
        const parseIssue = (val) => {
            const match = (val || '').match(/(\d+)/);
            return match ? parseInt(match[1], 10) : 0;
        };
        const parseYear = (val) => {
            const paren = (val || '').match(/[（(]([0-9]{4})[)）]/);
            if (paren) return parseInt(paren[1], 10);
            const fallback = (val || '').match(/(\d{4})/);
            return fallback ? parseInt(fallback[1], 10) : 0;
        };

        const rowData = rows.map((row) => {
            const cells = row.querySelectorAll('td');
            const issue = getText(cells[0]);
            const year = getText(cells[1]);
            const category = getText(cells[2]);
            const title = getText(cells[3]);
            const author = getText(cells[4]);
            const role = getText(cells[5]);
            return {
                row,
                issue,
                year,
                category,
                title,
                author,
                role,
                issueValue: parseIssue(issue),
                yearValue: parseYear(year),
                searchText: norm([issue, year, category, title, author, role].join(' '))
            };
        });
        const rowDataByRow = new Map(rowData.map((item) => [item.row, item]));
        const groupRowClass = 'kaihou-issue-row';
        const columnCount = kaihouTable.querySelectorAll('thead th').length;

        const clearIssueGroupRows = () => {
            tbody.querySelectorAll(`tr.${groupRowClass}`).forEach((row) => row.remove());
        };

        const buildIssueGroupRows = () => {
            clearIssueGroupRows();
            const orderedRows = Array.from(tbody.querySelectorAll('tr'))
                .filter((row) => !row.classList.contains(groupRowClass));
            const visibleRows = orderedRows.filter((row) => row.style.display !== 'none');
            if (!visibleRows.length) return;

            const issueCounts = new Map();
            visibleRows.forEach((row) => {
                const data = rowDataByRow.get(row);
                if (!data) return;
                issueCounts.set(data.issue, (issueCounts.get(data.issue) || 0) + 1);
            });

            let lastIssue = null;
            visibleRows.forEach((row) => {
                const data = rowDataByRow.get(row);
                if (!data) return;
                if (data.issue !== lastIssue) {
                    const groupRow = document.createElement('tr');
                    groupRow.className = groupRowClass;
                    const th = document.createElement('th');
                    th.colSpan = columnCount;
                    th.scope = 'rowgroup';

                    const issueChip = document.createElement('span');
                    issueChip.className = 'kaihou-issue-chip';
                    issueChip.textContent = data.issue;
                    th.appendChild(issueChip);

                    if (data.year) {
                        const yearMeta = document.createElement('span');
                        yearMeta.className = 'kaihou-issue-meta';
                        yearMeta.textContent = data.year;
                        th.appendChild(yearMeta);
                    }

                    const countLabel = document.createElement('span');
                    countLabel.className = 'kaihou-issue-count';
                    countLabel.textContent = `${issueCounts.get(data.issue) || 0}件`;
                    th.appendChild(countLabel);

                    groupRow.appendChild(th);
                    row.before(groupRow);
                    lastIssue = data.issue;
                }
            });
        };

        const applyDataLabels = () => {
            const headerLabels = Array.from(kaihouTable.querySelectorAll('thead th'))
                .map((th) => (th.textContent || '').trim());
            rows.forEach((row) => {
                row.querySelectorAll('td').forEach((cell, idx) => {
                    if (!cell.getAttribute('data-label')) {
                        cell.setAttribute('data-label', headerLabels[idx] || '');
                    }
                });
            });
        };

        const linkIssueCells = () => {
            rowData.forEach((item) => {
                const issueCell = item.row.querySelector('td:first-child');
                if (!issueCell || issueCell.querySelector('a')) return;
                if (!item.yearValue) return;
                const link = document.createElement('a');
                link.href = `kaihou.html#kaihou-${item.yearValue}`;
                link.textContent = item.issue;
                link.className = 'kaihou-issue-link';
                issueCell.textContent = '';
                issueCell.appendChild(link);
            });
        };

        const unique = (list) => Array.from(new Set(list)).filter(Boolean);
        const fillSelect = (select, values) => {
            if (!select) return;
            while (select.options.length > 1) select.remove(1);
            values.forEach((value) => {
                const option = document.createElement('option');
                option.value = value;
                option.textContent = value;
                select.appendChild(option);
            });
        };

        const issues = unique(rowData.map((d) => d.issue)).sort((a, b) => parseIssue(a) - parseIssue(b));
        const years = unique(rowData.map((d) => d.year)).sort((a, b) => parseYear(b) - parseYear(a));
        const categories = unique(rowData.map((d) => d.category)).sort((a, b) => a.localeCompare(b, 'ja'));
        fillSelect(issueSelect, issues);
        fillSelect(yearSelect, years);
        fillSelect(categorySelect, categories);

        const compareRows = (a, b, mode) => {
            switch (mode) {
                case 'year-asc':
                    return a.yearValue - b.yearValue || a.issueValue - b.issueValue;
                case 'issue-desc':
                    return b.issueValue - a.issueValue || b.yearValue - a.yearValue;
                case 'issue-asc':
                    return a.issueValue - b.issueValue || a.yearValue - b.yearValue;
                case 'category':
                    return a.category.localeCompare(b.category, 'ja') || b.yearValue - a.yearValue || b.issueValue - a.issueValue;
                case 'year-desc':
                default:
                    return b.yearValue - a.yearValue || b.issueValue - a.issueValue;
            }
        };

        const applySort = () => {
            clearIssueGroupRows();
            const mode = sortSelect ? sortSelect.value : 'year-desc';
            const sorted = rowData.slice().sort((a, b) => compareRows(a, b, mode));
            sorted.forEach((item) => tbody.appendChild(item.row));
        };

        const updateResultInfo = (visibleCount) => {
            if (!resultInfo) return;
            const total = rowData.length;
            if (visibleCount === 0) {
                resultInfo.textContent = `該当なし（全${total}件）`;
            } else {
                resultInfo.textContent = `全${total}件中 ${visibleCount}件表示`;
            }
        };

        const applyFilter = () => {
            const query = norm(searchField ? searchField.value.trim() : '');
            const issue = issueSelect ? issueSelect.value : '';
            const year = yearSelect ? yearSelect.value : '';
            const category = categorySelect ? categorySelect.value : '';
            let visibleCount = 0;

            rowData.forEach((item) => {
                const matchQuery = !query || item.searchText.includes(query);
                const matchIssue = !issue || item.issue === issue;
                const matchYear = !year || item.year === year;
                const matchCategory = !category || item.category === category;
                const match = matchQuery && matchIssue && matchYear && matchCategory;
                item.row.style.display = match ? '' : 'none';
                if (match) visibleCount++;
            });

            updateResultInfo(visibleCount);
            buildIssueGroupRows();
        };

        const resetFilters = () => {
            if (searchField) searchField.value = '';
            if (issueSelect) issueSelect.value = '';
            if (yearSelect) yearSelect.value = '';
            if (categorySelect) categorySelect.value = '';
            if (sortSelect) sortSelect.value = 'year-desc';
            applySort();
            applyFilter();
        };

        if (searchField) {
            searchField.addEventListener('input', () => {
                applyFilter();
            });
        }
        if (issueSelect) issueSelect.addEventListener('change', applyFilter);
        if (yearSelect) yearSelect.addEventListener('change', applyFilter);
        if (categorySelect) categorySelect.addEventListener('change', applyFilter);
        if (sortSelect) sortSelect.addEventListener('change', () => {
            applySort();
            applyFilter();
        });
        if (resetButton) resetButton.addEventListener('click', resetFilters);

        applyDataLabels();
        linkIssueCells();
        applySort();
        applyFilter();
    }

    // Dynamic copyright year
    document.querySelectorAll('.copyright-year').forEach(function(el) {
        el.textContent = new Date().getFullYear();
    });

    // URLハッシュに基づいてアコーディオンを開く
    if (window.location.hash) {
        const targetId = window.location.hash.substring(1);
        const targetElement = document.getElementById(targetId);
        if (targetElement && targetElement.classList.contains('accordion-item')) {
            const header = targetElement.querySelector('.accordion-header');
            if (header) {
                // アコーディオンを開く
                toggleAccordion(header, true);
                // スクロール位置を調整
                setTimeout(() => {
                    const nav = document.querySelector('nav');
                    const navHeight = nav ? nav.offsetHeight : 0;
                    const y = targetElement.getBoundingClientRect().top + window.pageYOffset - navHeight - 20;
                    window.scrollTo({ top: y, behavior: 'smooth' });
                }, 300);
            }
        }
    }
});
