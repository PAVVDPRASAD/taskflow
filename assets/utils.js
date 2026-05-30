
function escapeHtml(text) {
    if (!text) return '';
    return String(text)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;');
}

function getStatusBadge(status) {
    const badges = {
        'Pending': '<span class="status-badge bg-warn">Pending</span>',
        'In Progress': '<span class="status-badge bg-inf">In Progress</span>',
        'Completed': '<span class="status-badge bg-suc">Completed</span>'
    };
    return badges[status] || '<span class="badge bg-secondary">Unknown</span>';
}

