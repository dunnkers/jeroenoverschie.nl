// Renders TeX in the page with KaTeX's auto-render extension. Load it after
// the vendored KaTeX scripts, all with `defer` so they run in order:
//   <link rel="stylesheet" href="/assets/vendor/katex@0.19.1/katex.min.css">
//   <script defer src="/assets/vendor/katex@0.19.1/katex.min.js"></script>
//   <script defer src="/assets/vendor/katex@0.19.1/contrib/auto-render.min.js"></script>
//   <script defer src="/assets/page-scripts/render-math.1.js"></script>
// A file rather than an inline onload= handler, so the site's
// Content-Security-Policy can forbid inline scripts. Never edit it in place
// (/assets/ is cached for a year): copy to render-math.2.js instead.
renderMathInElement(document.body, {
    delimiters: [
        {left: '$$', right: '$$', display: true},
        {left: '$', right: '$', display: false},
        {left: '\\(', right: '\\)', display: false},
        {left: '\\begin{equation}', right: '\\end{equation}', display: true},
        {left: '\\begin{align}', right: '\\end{align}', display: true},
        {left: '\\begin{alignat}', right: '\\end{alignat}', display: true},
        {left: '\\begin{gather}', right: '\\end{gather}', display: true},
        {left: '\\begin{CD}', right: '\\end{CD}', display: true},
        {left: '\\[', right: '\\]', display: true}
    ]
});
