document.addEventListener('DOMContentLoaded', function () {
    // Toggle user dropdown
    const userDropdownToggle = document.getElementById('userDropdownToggle');
    const userDropdownMenu = document.getElementById('userDropdownMenu');
    const dropdownArrow = userDropdownToggle.querySelector('.dropdown-arrow');

    if (userDropdownToggle && userDropdownMenu) {
        userDropdownToggle.addEventListener('click', function (e) {
            e.preventDefault();
            e.stopPropagation();
            userDropdownMenu.classList.toggle('show');
            dropdownArrow.classList.toggle('rotated');
        });
    } else {
        console.log('Không tìm thấy userDropdownToggle hoặc userDropdownMenu');
    }

    // Đóng dropdown khi nhấn ra ngoài
    document.addEventListener('click', function (e) {
        if (!e.target.closest('.user-dropdown')) {
            userDropdownMenu.classList.remove('show');
            if (dropdownArrow) {
                dropdownArrow.classList.remove('rotated');
            }
        }
    });

    // Mobile menu toggle (nếu cần)
    const menuToggle = document.getElementById('menuToggle');
    if (menuToggle) {
        menuToggle.addEventListener('click', function () {
            document.querySelector('.main-nav').classList.toggle('active');
        });
    }
});