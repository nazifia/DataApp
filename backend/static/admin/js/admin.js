/**
 * ADP Admin Panel - Shared JavaScript Utilities
 */

/**
 * Fetch JSON from an API endpoint with error handling.
 */
async function fetchJSON(url, options = {}) {
    try {
        const response = await fetch(url, {
            ...options,
            headers: {
                'Content-Type': 'application/json',
                ...options.headers,
            },
        });

        if (!response.ok) {
            const error = await response.json().catch(() => ({ detail: 'Request failed' }));
            throw new Error(error.detail || `HTTP ${response.status}`);
        }

        return await response.json();
    } catch (error) {
        console.error('fetchJSON error:', error);
        throw error;
    }
}

/**
 * Render a table body from an array of items.
 */
function renderTable(tableBodyId, items, renderRow) {
    const tbody = document.getElementById(tableBodyId);
    if (!tbody) return;

    if (!items || items.length === 0) {
        tbody.innerHTML = `<tr><td colspan="100" class="px-4 py-8 text-center text-gray-400">No data found</td></tr>`;
        return;
    }

    tbody.innerHTML = items.map(renderRow).join('');
}

/**
 * Initialize a Chart.js chart.
 */
function initChart(canvasId, config) {
    const canvas = document.getElementById(canvasId);
    if (!canvas) return null;

    // Destroy existing chart if any
    const existingChart = Chart.getChart(canvas);
    if (existingChart) {
        existingChart.destroy();
    }

    return new Chart(canvas, config);
}

/**
 * Show a toast notification.
 */
function showToast(message, type = 'info') {
    const container = document.getElementById('toast-container');
    if (!container) return;

    const colors = {
        success: 'bg-green-500',
        error: 'bg-red-500',
        warning: 'bg-yellow-500',
        info: 'bg-blue-500',
    };

    const icons = {
        success: 'check-circle',
        error: 'x-circle',
        warning: 'alert-triangle',
        info: 'info',
    };

    const toast = document.createElement('div');
    toast.className = `flex items-center gap-3 px-4 py-3 rounded-lg text-white shadow-lg ${colors[type] || colors.info} transform transition-all duration-300 translate-x-full`;
    toast.innerHTML = `
        <i data-lucide="${icons[type] || icons.info}" class="w-5 h-5 flex-shrink-0"></i>
        <span class="text-sm">${message}</span>
    `;

    container.appendChild(toast);
    lucide.createIcons({ nodes: [toast] });

    // Animate in
    requestAnimationFrame(() => {
        toast.classList.remove('translate-x-full');
    });

    // Auto remove after 4 seconds
    setTimeout(() => {
        toast.classList.add('translate-x-full');
        setTimeout(() => toast.remove(), 300);
    }, 4000);
}

/**
 * Pagination helper - renders pagination controls.
 */
function renderPagination(containerId, currentPage, totalPages, onPageChange) {
    const container = document.getElementById(containerId);
    if (!container) return;

    if (totalPages <= 1) {
        container.innerHTML = '';
        return;
    }

    let html = '<nav class="flex items-center gap-1">';

    // Previous button
    html += `<button onclick="${onPageChange}(${currentPage - 1})" ${currentPage <= 1 ? 'disabled' : ''}
              class="px-3 py-1 rounded border ${currentPage <= 1 ? 'bg-gray-100 text-gray-400 cursor-not-allowed' : 'hover:bg-gray-100'}">
              Prev</button>`;

    // Page numbers
    const maxVisible = 5;
    let start = Math.max(1, currentPage - Math.floor(maxVisible / 2));
    let end = Math.min(totalPages, start + maxVisible - 1);
    if (end - start < maxVisible - 1) {
        start = Math.max(1, end - maxVisible + 1);
    }

    if (start > 1) {
        html += `<button onclick="${onPageChange}(1)" class="px-3 py-1 rounded border hover:bg-gray-100">1</button>`;
        if (start > 2) html += '<span class="px-2">...</span>';
    }

    for (let i = start; i <= end; i++) {
        html += `<button onclick="${onPageChange}(${i})"
                  class="px-3 py-1 rounded border ${i === currentPage ? 'bg-blue-600 text-white' : 'hover:bg-gray-100'}">
                  ${i}</button>`;
    }

    if (end < totalPages) {
        if (end < totalPages - 1) html += '<span class="px-2">...</span>';
        html += `<button onclick="${onPageChange}(${totalPages})" class="px-3 py-1 rounded border hover:bg-gray-100">${totalPages}</button>`;
    }

    // Next button
    html += `<button onclick="${onPageChange}(${currentPage + 1})" ${currentPage >= totalPages ? 'disabled' : ''}
              class="px-3 py-1 rounded border ${currentPage >= totalPages ? 'bg-gray-100 text-gray-400 cursor-not-allowed' : 'hover:bg-gray-100'}">
              Next</button>`;

    html += '</nav>';
    container.innerHTML = html;
}

/**
 * Format currency (Naira).
 */
function formatCurrency(amount) {
    return '₦' + Number(amount).toLocaleString('en-NG', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

/**
 * Format date string.
 */
function formatDate(dateStr) {
    if (!dateStr) return '-';
    const date = new Date(dateStr);
    return date.toLocaleDateString('en-NG', { year: 'numeric', month: 'short', day: 'numeric' });
}

/**
 * Format datetime string.
 */
function formatDateTime(dateStr) {
    if (!dateStr) return '-';
    const date = new Date(dateStr);
    return date.toLocaleDateString('en-NG', { year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
}

/**
 * Get status badge HTML.
 */
function statusBadge(status) {
    const colors = {
        success: 'bg-green-100 text-green-800',
        pending: 'bg-yellow-100 text-yellow-800',
        failed: 'bg-red-100 text-red-800',
        active: 'bg-green-100 text-green-800',
        inactive: 'bg-gray-100 text-gray-800',
    };
    return `<span class="px-2 py-1 text-xs font-medium rounded-full ${colors[status] || 'bg-gray-100 text-gray-800'}">${status}</span>`;
}

/**
 * Confirm action modal.
 */
function confirmAction(message, onConfirm) {
    if (confirm(message)) {
        onConfirm();
    }
}
