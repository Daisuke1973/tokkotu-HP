document.addEventListener('DOMContentLoaded', function() {
    // Accordion functionality
    const accordionHeaders = document.querySelectorAll('.accordion-header');
    accordionHeaders.forEach(header => {
        header.addEventListener('click', () => {
            toggleAccordion(header);
        });
    });

    function toggleAccordion(header, open) {
        const accordionItem = header.parentElement;
        const accordionContent = header.nextElementSibling;
        const isActive = header.classList.contains('active');

        if (open === true && !isActive) {
            header.classList.add('active');
            accordionContent.style.maxHeight = accordionContent.scrollHeight + "px";
            accordionItem.classList.add('active');
        } else if (open === false && isActive) {
            header.classList.remove('active');
            accordionContent.style.maxHeight = null;
            accordionItem.classList.remove('active');
        } else if (open === undefined) {
            header.classList.toggle('active');
            if (accordionContent.style.maxHeight) {
                accordionContent.style.maxHeight = null;
                accordionItem.classList.remove('active');
            } else {
                accordionContent.style.maxHeight = accordionContent.scrollHeight + "px";
                accordionItem.classList.add('active');
            }
        }
    }

    // Image Modal functionality
    const modal = document.getElementById("imageModal");
    const modalImg = document.getElementById("img01");
    const images = document.querySelectorAll('.image-grid img, .image-gallery img');
    const closeBtn = document.querySelector(".modal .close");

    images.forEach(img => {
        img.onclick = function(){
            modal.style.display = "block";
            modalImg.src = this.src;
        }
    });

    if(closeBtn) {
        closeBtn.onclick = function() {
            modal.style.display = "none";
        }
    }

    window.onclick = function(event) {
        if (event.target == modal) {
            modal.style.display = "none";
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
});