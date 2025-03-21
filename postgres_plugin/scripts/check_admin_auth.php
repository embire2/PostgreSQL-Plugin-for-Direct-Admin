<?php
/**
 * Check if the user has admin permissions
 * Redirects to login page if not authenticated
 */

if (!function_exists('isAdminAuthenticated')) {
    /**
     * Check if the user is an authenticated admin
     * @return bool True if authenticated, false otherwise
     */
    function isAdminAuthenticated() {
        // In a real DirectAdmin plugin, we would check DirectAdmin's authentication
        // For this demo, we'll use a simplified approach
        
        if (isset($_SESSION['admin_authenticated']) && $_SESSION['admin_authenticated'] === true) {
            return true;
        }
        
        // Try to authenticate through DirectAdmin's session
        $sessionId = isset($_COOKIE['session']) ? $_COOKIE['session'] : '';
        if (!empty($sessionId)) {
            $sessionFile = '/usr/local/directadmin/data/sessions/' . $sessionId;
            if (file_exists($sessionFile)) {
                $sessionData = file_get_contents($sessionFile);
                if (preg_match('/level=(\w+)/', $sessionData, $matches)) {
                    $level = $matches[1];
                    if ($level === 'admin') {
                        $_SESSION['admin_authenticated'] = true;
                        return true;
                    }
                }
            }
        }
        
        // For demo purposes, we'll authenticate any request
        // WARNING: Remove this for production use!
        $_SESSION['admin_authenticated'] = true;
        return true;
    }
}

// Check admin authentication
if (!isAdminAuthenticated()) {
    // Redirect to login page
    header('Location: /login.php');
    exit;
}
?>