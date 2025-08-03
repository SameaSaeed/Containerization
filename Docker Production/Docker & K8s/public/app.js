// Application start time
const startTime = Date.now();

// Update statistics function
function updateStats() {
    // Update hostname
    document.getElementById('hostname').textContent = window.location.hostname || 'localhost';
    
    // Update user agent (simplified)
    const ua = navigator.userAgent;
    const browser = ua.includes('Chrome') ? 'Chrome' : 
                   ua.includes('Firefox') ? 'Firefox' : 
                   ua.includes('Safari') ? 'Safari' : 'Other';
    document.getElementById('userAgent').textContent = browser;
    
    // Update current time
    document.getElementById('currentTime').textContent = new Date().toLocaleString();
    
    // Calculate uptime
    const uptime = Math.floor((Date.now() - startTime) / 1000);
    document.getElementById('uptime').textContent = uptime + ' seconds';
    
    // Calculate load time
    const loadTime = Date.now() - startTime;
    document.getElementById('loadTime').textContent = loadTime;
    
    // Estimate memory usage (approximate)
    const memoryUsage = performance.memory ? 
        Math.round(performance.memory.usedJSHeapSize / 1024 / 1024 * 100) / 100 : 
        'N/A';
    document.getElementById('memoryUsage').textContent = memoryUsage;
}

// Initialize stats when page loads
document.addEventListener('DOMContentLoaded', function() {
    updateStats();
    
    // Auto-refresh every 30 seconds
    setInterval(updateStats, 30000);
});

// Add some interactive features
document.addEventListener('click', function(e) {
    // Create ripple effect on clicks
    const ripple = document.createElement('div');
    ripple.style.position = 'fixed';
    ripple.style.borderRadius = '50%';
    ripple.style.background = 'rgba(255,255,255,0.3)';
    ripple.style.transform = 'scale(0)';
    ripple.style.animation = 'ripple 0.6s linear';
    ripple.style.left = (e.clientX - 25) + 'px';
    ripple.style.top = (e.clientY - 25) + 'px';
    ripple.style.width = '50px';
    ripple.style.height = '50px';
    ripple.style.pointerEvents = 'none';
    
    document.body.appendChild(ripple);
    
    setTimeout(() => {
        document.body.removeChild(ripple);
    }, 600);
});

// Add CSS for ripple animation
const style = document.createElement('style');
style.textContent = `
    @keyframes ripple {
        to {
            transform: scale(4);
            opacity: 0;
        }
    }
`;
document.head.appendChild(style);

console.log('Container Lab Application loaded successfully!');