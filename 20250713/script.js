// script.js の中身はこれです

document.addEventListener('DOMContentLoaded', function() {
    
    // --- ここからアコーディオンと検索のコード ---
    // ページに要素が存在するか確認してから処理を実行します
    const accordionHeaders = document.querySelectorAll('.accordion-header');
    const yearSearchInput = document.getElementById('yearSearch');
    const accordionItems = document.querySelectorAll('.ayumi-accordion-container .accordion-item');

    // accordionHeaders がページに存在する場合のみ実行
    if (accordionHeaders.length > 0) {
        accordionHeaders.forEach(header => {
            header.addEventListener('click', function() {
                const accordionItem = this.closest('.accordion-item');
                const content = accordionItem.querySelector('.accordion-content');

                // header にも active クラスをトグル
                this.classList.toggle('active');
                accordionItem.classList.toggle('active');
                
                if (content.style.maxHeight) {
                    content.style.maxHeight = null;
                } else {
                    content.style.maxHeight = content.scrollHeight + "px";
                }
            });
        });
    }

    // yearSearchInput がページに存在する場合のみ実行
    if (yearSearchInput) {
        yearSearchInput.addEventListener('keyup', function() {
            const searchTerm = yearSearchInput.value.toLowerCase();

            accordionItems.forEach(item => {
                const yearText = item.querySelector('.accordion-header span:first-child').textContent.toLowerCase();
                const subText = item.querySelector('.accordion-header .sub-text') ? item.querySelector('.accordion-header .sub-text').textContent.toLowerCase() : '';

                if (yearText.includes(searchTerm) || subText.includes(searchTerm)) {
                    item.style.display = '';
                } else {
                    item.style.display = 'none';
                }
            });
        });
    }
    
    // --- ここからナビゲーションをハイライトするコード ---
    const currentPath = window.location.pathname.split('/').pop() || 'index.html'; // ページ名が空の場合は index.html とする
    const navLinks = document.querySelectorAll('nav a');

    navLinks.forEach(link => {
        const linkPath = link.getAttribute('href');
        if (linkPath === currentPath) {
            link.classList.add('active');
        }
    });

    // --- ここからモーダル（画像拡大）のコード ---
    // ページに要素が存在するか確認してから処理を実行します
    const modal = document.getElementById("imageModal");
    if (modal) {
        const modalImg = document.getElementById("img01");
        const galleryImages = document.querySelectorAll(".image-grid img, .image-gallery img");
        const span = document.getElementsByClassName("close")[0];

        galleryImages.forEach(img => {
            img.onclick = function(){
                modal.style.display = "block";
                modalImg.src = this.src;
            }
        });

        if(span) {
            span.onclick = function() { 
                modal.style.display = "none";
            }
        }
        
        modal.onclick = function(event) {
            if (event.target === modal) {
                modal.style.display = "none";
            }
        }
    }
    
    // --- ここから kouka.html のアコーディオンコード ---
    // ページに要素が存在するか確認してから処理を実行します
    const songSections = document.querySelectorAll('.song-section');
    if (songSections.length > 0) {
        songSections.forEach(accordion => {
            const header = accordion.querySelector('.accordion-header');
            const content = accordion.querySelector('.lyrics-content');

            header.addEventListener('click', () => {
                header.classList.toggle('active');
                content.classList.toggle('show');

                if (content.style.maxHeight) {
                    content.style.maxHeight = null;
                } else {
                    content.style.maxHeight = content.scrollHeight + "px";
                }
            });
        });
    }

    // 他のページで使われているアコーディオンのコードもここに統合できます。
    // （現状のコードで多くのケースをカバーできています）
});