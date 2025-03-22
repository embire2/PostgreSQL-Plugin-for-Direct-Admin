<?php
/**
 * Check if the user is authenticated
 * Redirects to login page if not authenticated
 */

if (!function_exists('isUserAuthenticated')) {
    /**
     * Check if the user is authenticated
     * @return bool True if authenticated, false otherwise
     */
    function isUserAuthenticated() {
        // In a real DirectAdmin plugin, we would check DirectAdmin's authentication
        // For this demo, we'll use a simplified approach
        
        if (isset($_SESSION['user_authenticated']) && $_SESSION['user_authenticated'] === true) {
            return true;
        }
        
        // Try to authenticate through DirectAdmin's session
        $sessionId = isset($_COOKIE['session']) ? $_COOKIE['session'] : '';
        if (!empty($sessionId)) {
            $sessionFile = '/usr/local/directadmin/data/sessions/' . $sessionId;
            if (file_exists($sessionFile)) {
                $sessionData = file_get_contents($sessionFile);
                if (preg_match('/username=([^\n]+)/', $sessionData, $matches)) {
                    // Store the username in the session
                    $_SESSION['username'] = $matches[1];
                    $_SESSION['user_authenticated'] = true;
                    return true;
                }
            }
        }
        
        // For demo purposes, we'll authenticate any request and set a default username
        // WARNING: Remove this for production use!
        $_SESSION['username'] = 'demo_user';
        $_SESSION['user_authenticated'] = true;
        return true;
    }
}

// Check user authentication
if (!isUserAuthenticated()) {
    // Redirect to login page
    header('Location: /login.php');
    exit;
}
?>