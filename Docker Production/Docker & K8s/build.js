const fs = require('fs');
const UglifyJS = require('uglify-js');

// Read the source JavaScript file
const sourceCode = fs.readFileSync('public/app.js', 'utf8');

// Minify the JavaScript
const minified = UglifyJS.minify(sourceCode);

if (minified.error) {
    console.error('Minification error:', minified.error);
    process.exit(1);
}

// Write the minified code to dist directory
fs.writeFileSync('dist/app.min.js', minified.code);

// Copy and optimize HTML
let html = fs.readFileSync('public/index.html', 'utf8');
html = html.replace('app.js', 'app.min.js');
html = html.replace(/\s+/g, ' ').trim(); // Basic HTML minification

fs.writeFileSync('dist/index.html', html);

console.log('Build completed successfully!');