/**
 * Main JavaScript file for PostgreSQL DirectAdmin plugin - User Panel
 */

// Initialize common components when the document is ready
$(document).ready(function() {
    // Initialize Feather icons
    if (typeof feather !== 'undefined') {
        feather.replace();
    }

    // Set up authentication token for AJAX requests if available
    const authToken = getAuthToken();
    if (authToken) {
        $.ajaxSetup({
            headers: {
                'X-Auth-Token': authToken
            }
        });
    }

    // Add global AJAX error handling
    $(document).ajaxError(function(event, jqxhr, settings, thrownError) {
        // Check if the error is an authentication error
        if (jqxhr.status === 401) {
            alert('Your session has expired. Please log in again.');
            window.location.href = '/CMD_LOGIN';
            return;
        }

        // Log error details to console for debugging
        console.error('AJAX Error:', thrownError);
        console.error('Response:', jqxhr.responseText);
    });

    // Handle any alert auto-dismissal
    setTimeout(function() {
        $('.alert-auto-dismiss').fadeOut('slow');
    }, 5000);
});

/**
 * Get authentication token from cookies or local storage
 * @returns {string|null} Authentication token or null if not found
 */
function getAuthToken() {
    // Try to get from localStorage first
    const token = localStorage.getItem('da_auth_token');
    if (token) {
        return token;
    }

    // If not in localStorage, try cookies
    return getCookie('DA_AUTH_TOKEN');
}

/**
 * Helper function to get a cookie value by name
 * @param {string} name - Cookie name
 * @returns {string|null} Cookie value or null if not found
 */
function getCookie(name) {
    const value = `; ${document.cookie}`;
    const parts = value.split(`; ${name}=`);
    if (parts.length === 2) {
        return parts.pop().split(';').shift();
    }
    return null;
}

/**
 * Format a file size in bytes to a human-readable format
 * @param {number} bytes - Size in bytes
 * @param {number} decimals - Number of decimal places
 * @returns {string} Formatted file size string
 */
function formatBytes(bytes, decimals = 2) {
    if (bytes === 0) return '0 Bytes';

    const k = 1024;
    const dm = decimals < 0 ? 0 : decimals;
    const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];

    const i = Math.floor(Math.log(bytes) / Math.log(k));

    return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
}

/**
 * Generate a random password with specified length and complexity
 * @param {number} length - Password length
 * @param {boolean} includeSpecial - Whether to include special characters
 * @returns {string} Generated password
 */
function generateRandomPassword(length = 12, includeSpecial = true) {
    let charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    const specialChars = "!@#$%^&*()-_=+";
    
    if (includeSpecial) {
        charset += specialChars;
    }
    
    let password = "";
    for (let i = 0; i < length; i++) {
        const randomIndex = Math.floor(Math.random() * charset.length);
        password += charset[randomIndex];
    }
    
    // Ensure password contains at least one of each required character type
    const hasLowercase = /[a-z]/.test(password);
    const hasUppercase = /[A-Z]/.test(password);
    const hasNumber = /[0-9]/.test(password);
    const hasSpecial = includeSpecial ? new RegExp('[' + specialChars.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, '\\$&') + ']').test(password) : true;
    
    if (!hasLowercase || !hasUppercase || !hasNumber || !hasSpecial) {
        // If password doesn't meet requirements, generate a new one
        return generateRandomPassword(length, includeSpecial);
    }
    
    return password;
}

/**
 * Show an alert message that disappears after a timeout
 * @param {string} message - Message to display
 * @param {string} type - Alert type (success, info, warning, danger)
 * @param {string} containerId - ID of the container element
 * @param {number} timeout - Time in milliseconds before alert disappears
 */
function showTemporaryAlert(message, type = 'success', containerId = 'alert-container', timeout = 3000) {
    const container = document.getElementById(containerId);
    if (!container) {
        console.error(`Container with ID '${containerId}' not found.`);
        return;
    }
    
    // Create alert element
    const alertEl = document.createElement('div');
    alertEl.className = `alert alert-${type} alert-dismissible fade show`;
    alertEl.role = 'alert';
    alertEl.innerHTML = `
        ${message}
        <button type="button" class="close" data-dismiss="alert" aria-label="Close">
            <span aria-hidden="true">&times;</span>
        </button>
    `;
    
    // Add to container
    container.appendChild(alertEl);
    
    // Remove after timeout
    setTimeout(() => {
        $(alertEl).alert('close');
    }, timeout);
}

/**
 * Validate a database name to ensure it contains only allowed characters
 * @param {string} name - Database name to validate
 * @returns {boolean} True if valid, false otherwise
 */
function isValidDatabaseName(name) {
    // PostgreSQL database names should start with a letter or underscore
    // and can contain letters, numbers, and underscores
    return /^[a-zA-Z_][a-zA-Z0-9_]*$/.test(name);
}

/**
 * Validate a username to ensure it contains only allowed characters
 * @param {string} username - Username to validate
 * @returns {boolean} True if valid, false otherwise
 */
function isValidUsername(username) {
    // PostgreSQL usernames follow similar rules to database names
    return /^[a-zA-Z_][a-zA-Z0-9_]*$/.test(username);
}

/**
 * Validate a password to ensure it meets minimum complexity requirements
 * @param {string} password - Password to validate
 * @returns {boolean} True if valid, false otherwise
 */
function isStrongPassword(password) {
    // At least 8 characters, containing lowercase, uppercase, number
    return password.length >= 8 && 
           /[a-z]/.test(password) && 
           /[A-Z]/.test(password) && 
           /[0-9]/.test(password);
}

/**
 * Show confirmation dialog with customizable buttons
 * @param {string} message - Message to display
 * @param {string} title - Dialog title
 * @param {function} onConfirm - Callback function when confirmed
 * @param {string} confirmBtnText - Text for the confirm button
 * @param {string} confirmBtnClass - CSS class for the confirm button
 * @returns {void}
 */
function showConfirmDialog(message, title = 'Confirm', onConfirm, confirmBtnText = 'Confirm', confirmBtnClass = 'btn-primary') {
    // Create a modal if it doesn't exist
    if (!document.getElementById('dynamicConfirmModal')) {
        const modal = document.createElement('div');
        modal.className = 'modal fade';
        modal.id = 'dynamicConfirmModal';
        modal.setAttribute('tabindex', '-1');
        modal.setAttribute('role', 'dialog');
        modal.setAttribute('aria-labelledby', 'confirmModalLabel');
        modal.setAttribute('aria-hidden', 'true');
        
        modal.innerHTML = `
            <div class="modal-dialog" role="document">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title" id="confirmModalLabel">${title}</h5>
                        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                            <span aria-hidden="true">&times;</span>
                        </button>
                    </div>
                    <div class="modal-body" id="confirmModalBody">
                        ${message}
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-dismiss="modal">Cancel</button>
                        <button type="button" class="btn ${confirmBtnClass}" id="confirmModalBtn">${confirmBtnText}</button>
                    </div>
                </div>
            </div>
        `;
        
        document.body.appendChild(modal);
    } else {
        // Update existing modal
        document.getElementById('confirmModalLabel').textContent = title;
        document.getElementById('confirmModalBody').innerHTML = message;
        document.getElementById('confirmModalBtn').textContent = confirmBtnText;
        document.getElementById('confirmModalBtn').className = `btn ${confirmBtnClass}`;
    }
    
    // Set up confirm button handler
    const confirmBtn = document.getElementById('confirmModalBtn');
    
    // Remove previous event listeners
    const newConfirmBtn = confirmBtn.cloneNode(true);
    confirmBtn.parentNode.replaceChild(newConfirmBtn, confirmBtn);
    
    // Add new event listener
    newConfirmBtn.addEventListener('click', function() {
        if (typeof onConfirm === 'function') {
            onConfirm();
        }
        $('#dynamicConfirmModal').modal('hide');
    });
    
    // Show the modal
    $('#dynamicConfirmModal').modal('show');
}
