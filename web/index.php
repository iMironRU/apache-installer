<?php
/**
 * index.php — актуальная ссылка на дистрибутив Apache для Windows
 *
 * GET /index.php           → HTML со ссылками на Win32 и Win64
 * GET /index.php?arch=64   → plain text, прямая ссылка на Win64
 * GET /index.php?arch=32   → plain text, прямая ссылка на Win32
 * GET /index.php?debug=1   → plain text, диагностика (удалить на проде)
 */

$DOWNLOAD_PAGE = 'https://www.apachelounge.com/download/';

function fetch_links($page_url) {
    $ctx = stream_context_create(array(
        'http' => array(
            'header'          => "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)\r\n",
            'timeout'         => 10,
            'follow_location' => 1,
        ),
    ));

    $html = @file_get_contents($page_url, false, $ctx);
    if ($html === false) {
        return array('error' => 'Не удалось загрузить страницу ' . $page_url);
    }

    $links = array('32' => null, '64' => null);

    if (preg_match_all(
        '/<a\s[^>]*href=["\']([^"\']*httpd-[\d.]+-\d+-win(?:32|64)-vs\d+\.zip)["\'][^>]*>/i',
        $html, $matches, PREG_SET_ORDER
    )) {
        foreach ($matches as $m) {
            $href = $m[1];
            $filename = basename($href);
            if (!preg_match('#^https?://#i', $href)) {
                $href = 'https://www.apachelounge.com/' . ltrim($href, '/');
            }
            if (preg_match('/win64/i', $filename) && $links['64'] === null) $links['64'] = $href;
            elseif (preg_match('/win32/i', $filename) && $links['32'] === null) $links['32'] = $href;
        }
    }

    if ($links['64'] === null || $links['32'] === null) {
        preg_match('#(https://www\.apachelounge\.com/download/VS\d+/binaries/)#i', $html, $baseMatch);
        $base = isset($baseMatch[1]) ? $baseMatch[1] : 'https://www.apachelounge.com/download/VS18/binaries/';
        preg_match_all('/(httpd-[\d.]+-\d+-win(?:32|64)-vs\d+\.zip)/i', $html, $nameMatches);
        foreach ($nameMatches[1] as $filename) {
            if (preg_match('/win64/i', $filename) && $links['64'] === null) $links['64'] = $base . $filename;
            elseif (preg_match('/win32/i', $filename) && $links['32'] === null) $links['32'] = $base . $filename;
        }
    }

    return $links;
}

if (isset($_GET['debug'])) {
    header('Content-Type: text/plain; charset=utf-8');
    $links = fetch_links($DOWNLOAD_PAGE);
    echo "PHP version    : " . PHP_VERSION . "\n";
    echo "allow_url_fopen: " . (ini_get('allow_url_fopen') ? 'on' : 'off') . "\n\n";
    echo "Win64 : " . (isset($links['64']) && $links['64'] ? $links['64'] : 'НЕ НАЙДЕНО') . "\n";
    echo "Win32 : " . (isset($links['32']) && $links['32'] ? $links['32'] : 'НЕ НАЙДЕНО') . "\n";
    if (isset($links['error'])) echo "\nОшибка: " . $links['error'] . "\n";
    exit;
}

$arch = isset($_GET['arch']) ? trim($_GET['arch']) : null;

if ($arch !== null && $arch !== '32' && $arch !== '64') {
    http_response_code(400);
    header('Content-Type: text/plain; charset=utf-8');
    echo "Ошибка: параметр arch должен быть 32 или 64.\nПример: ?arch=64\n";
    exit;
}

$links = fetch_links($DOWNLOAD_PAGE);

if ($arch !== null) {
    header('Content-Type: text/plain; charset=utf-8');
    header('Cache-Control: public, max-age=3600');
    if (isset($links['error'])) { http_response_code(502); echo $links['error']; exit; }
    if (empty($links[$arch])) { http_response_code(404); echo "Not found: ссылка для Win{$arch} не обнаружена.\n"; exit; }
    echo $links[$arch];
    exit;
}

if (isset($links['error'])) {
    $ver64 = $ver32 = 'ошибка загрузки';
    $err = $links['error'];
} else {
    $ver64 = !empty($links['64']) ? basename($links['64']) : 'не найдено';
    $ver32 = !empty($links['32']) ? basename($links['32']) : 'не найдено';
    $err = null;
}
?><!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Apache Windows — imiron.ru</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;600&family=Unbounded:wght@400;700&display=swap" rel="stylesheet">
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

    :root {
      --bg:       #858F93;
      --bg-dark:  #6e7b80;
      --bg-card:  rgba(255,255,255,0.13);
      --bg-code:  rgba(0,0,0,0.18);
      --border:   rgba(255,255,255,0.22);
      --text:     #ffffff;
      --text-dim: rgba(255,255,255,0.6);
      --text-faint: rgba(255,255,255,0.35);
      --accent:   #ffffff;
      --shadow:   0 8px 32px rgba(0,0,0,0.18);
    }

    body {
      font-family: 'JetBrains Mono', monospace;
      background: var(--bg);
      color: var(--text);
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      padding: 48px 20px 60px;
      position: relative;
      overflow-x: hidden;
    }

    /* subtle grain overlay */
    body::before {
      content: '';
      position: fixed;
      inset: 0;
      background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 200 200' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)' opacity='0.04'/%3E%3C/svg%3E");
      background-size: 180px;
      pointer-events: none;
      z-index: 0;
      opacity: .5;
    }

    /* diagonal stripe texture */
    body::after {
      content: '';
      position: fixed;
      inset: 0;
      background: repeating-linear-gradient(
        -45deg,
        transparent,
        transparent 40px,
        rgba(255,255,255,0.025) 40px,
        rgba(255,255,255,0.025) 41px
      );
      pointer-events: none;
      z-index: 0;
    }

    .wrap {
      position: relative;
      z-index: 1;
      width: 100%;
      max-width: 540px;
      display: flex;
      flex-direction: column;
      align-items: center;
    }

    /* ── Header / Logo ── */
    .logo-link {
      display: flex;
      flex-direction: column;
      align-items: center;
      text-decoration: none;
      margin-bottom: 44px;
      gap: 12px;
      transition: opacity .2s;
    }
    .logo-link:hover { opacity: .8; }

    .logo-avatar {
      width: 72px;
      height: 72px;
      border-radius: 50%;
      border: 2px solid rgba(255,255,255,0.4);
      overflow: hidden;
      background: rgba(255,255,255,0.1);
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .logo-avatar img { width: 100%; height: 100%; object-fit: cover; }

    .logo-title img {
      height: 22px;
      filter: brightness(0) invert(1);
      opacity: .9;
    }

    /* ── Page title ── */
    .page-title {
      font-family: 'Unbounded', sans-serif;
      font-size: 13px;
      font-weight: 700;
      letter-spacing: .15em;
      text-transform: uppercase;
      color: var(--text-dim);
      margin-bottom: 6px;
      text-align: center;
    }
    .page-sub {
      font-size: 11px;
      color: var(--text-faint);
      margin-bottom: 32px;
      text-align: center;
    }

    /* ── Error ── */
    .error-box {
      width: 100%;
      background: rgba(200,60,60,0.18);
      border: 1px solid rgba(255,100,100,0.3);
      border-radius: 10px;
      padding: 12px 16px;
      font-size: 12px;
      color: #ffaaaa;
      margin-bottom: 20px;
    }

    /* ── Cards ── */
    .card {
      width: 100%;
      background: var(--bg-card);
      border: 1px solid var(--border);
      border-radius: 16px;
      padding: 24px 28px;
      margin-bottom: 14px;
      backdrop-filter: blur(8px);
      -webkit-backdrop-filter: blur(8px);
      box-shadow: var(--shadow);
      transition: transform .2s, box-shadow .2s;
    }
    .card:hover {
      transform: translateY(-2px);
      box-shadow: 0 12px 40px rgba(0,0,0,0.22);
    }

    .card-head {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 14px;
    }

    .card-label {
      font-family: 'Unbounded', sans-serif;
      font-size: 12px;
      font-weight: 700;
      letter-spacing: .08em;
      color: var(--text);
    }

    .badge {
      font-size: 10px;
      font-weight: 600;
      padding: 3px 10px;
      border-radius: 20px;
      border: 1px solid rgba(255,255,255,0.3);
      color: rgba(255,255,255,0.7);
      letter-spacing: .05em;
    }

    .filename {
      font-size: 11px;
      color: var(--text-dim);
      background: var(--bg-code);
      border-radius: 8px;
      padding: 9px 12px;
      margin-bottom: 16px;
      word-break: break-all;
      border: 1px solid rgba(255,255,255,0.08);
    }
    .filename.na { color: rgba(255,140,140,0.7); }

    .btn-row { display: flex; gap: 10px; flex-wrap: wrap; }

    .btn {
      display: inline-block;
      font-family: 'JetBrains Mono', monospace;
      font-size: 11px;
      font-weight: 600;
      padding: 8px 18px;
      border-radius: 8px;
      text-decoration: none;
      transition: opacity .18s, transform .18s;
      letter-spacing: .03em;
    }
    .btn:hover { opacity: .85; transform: translateY(-1px); }

    .btn-dl {
      background: #fff;
      color: var(--bg-dark);
    }
    .btn-api {
      background: transparent;
      border: 1px solid rgba(255,255,255,0.3);
      color: rgba(255,255,255,0.7);
    }

    /* ── API block ── */
    .api-block {
      width: 100%;
      background: var(--bg-code);
      border: 1px solid rgba(255,255,255,0.1);
      border-radius: 12px;
      padding: 18px 22px;
      margin-top: 6px;
    }
    .api-head {
      font-family: 'Unbounded', sans-serif;
      font-size: 9px;
      letter-spacing: .15em;
      text-transform: uppercase;
      color: var(--text-faint);
      margin-bottom: 12px;
    }
    .api-row {
      font-size: 11px;
      color: var(--text-dim);
      margin-bottom: 5px;
      display: flex;
      gap: 8px;
    }
    .api-row:last-child { margin-bottom: 0; }
    .api-method { color: rgba(255,255,255,0.4); min-width: 30px; }

    /* ── GitHub link ── */
    .github-link {
      display: inline-flex;
      align-items: center;
      gap: 7px;
      margin-top: 20px;
      font-size: 11px;
      color: rgba(255,255,255,0.5);
      text-decoration: none;
      border: 1px solid rgba(255,255,255,0.18);
      border-radius: 20px;
      padding: 6px 14px;
      transition: color .18s, border-color .18s, transform .18s;
    }
    .github-link:hover {
      color: #fff;
      border-color: rgba(255,255,255,0.45);
      transform: translateY(-1px);
    }

    /* ── Footer ── */
    .footer {
      margin-top: 32px;
      font-size: 10px;
      color: var(--text-faint);
      text-align: center;
    }
    .footer a { color: rgba(255,255,255,0.45); text-decoration: none; }
    .footer a:hover { color: #fff; }
  </style>
</head>
<body>
<div class="wrap">

  <!-- Logo -->
  <a class="logo-link" href="https://imiron.ru" target="_blank" rel="noopener">
    <div class="logo-avatar">
      <img src="https://imiron.ru/images/foto.svg" alt="imiron avatar">
    </div>
    <div class="logo-title">
      <img src="https://imiron.ru/images/title.svg" alt="imiron">
    </div>
  </a>

  <div class="page-title">Apache for Windows</div>
  <p class="page-sub">актуальные ссылки · apachelounge.com</p>

  <?php if ($err): ?>
  <div class="error-box"><?= htmlspecialchars($err) ?></div>
  <?php endif; ?>

  <!-- Win64 -->
  <div class="card">
    <div class="card-head">
      <span class="card-label">Windows 64-bit</span>
      <span class="badge">x64</span>
    </div>
    <div class="filename <?= !empty($links['64']) ? '' : 'na' ?>"><?= htmlspecialchars($ver64) ?></div>
    <?php if (!empty($links['64'])): ?>
    <div class="btn-row">
      <a class="btn btn-dl"  href="<?= htmlspecialchars($links['64']) ?>">↓ скачать .zip</a>
      <a class="btn btn-api" href="?arch=64">api-ссылка</a>
    </div>
    <?php endif; ?>
  </div>

  <!-- Win32 -->
  <div class="card">
    <div class="card-head">
      <span class="card-label">Windows 32-bit</span>
      <span class="badge">x86</span>
    </div>
    <div class="filename <?= !empty($links['32']) ? '' : 'na' ?>"><?= htmlspecialchars($ver32) ?></div>
    <?php if (!empty($links['32'])): ?>
    <div class="btn-row">
      <a class="btn btn-dl"  href="<?= htmlspecialchars($links['32']) ?>">↓ скачать .zip</a>
      <a class="btn btn-api" href="?arch=32">api-ссылка</a>
    </div>
    <?php endif; ?>
  </div>

  <!-- API -->
  <div class="api-block">
    <div class="api-head">использование в скриптах</div>
    <div class="api-row"><span class="api-method">GET</span> ?arch=64 → прямая ссылка Win64 (plain text)</div>
    <div class="api-row"><span class="api-method">GET</span> ?arch=32 → прямая ссылка Win32 (plain text)</div>
    <div class="api-row"><span class="api-method">GET</span> ?debug=1 → диагностика сервера</div>
  </div>

  <a class="github-link" href="https://github.com/iMironRU/apache-installer" target="_blank" rel="noopener">
    <svg width="15" height="15" viewBox="0 0 24 24" fill="currentColor"><path d="M12 0C5.37 0 0 5.37 0 12c0 5.31 3.435 9.795 8.205 11.385.6.105.825-.255.825-.57 0-.285-.015-1.23-.015-2.235-3.015.555-3.795-.735-4.035-1.41-.135-.345-.72-1.41-1.23-1.695-.42-.225-1.02-.78-.015-.795.945-.015 1.62.87 1.845 1.23 1.08 1.815 2.805 1.305 3.495.99.105-.78.42-1.305.765-1.605-2.67-.3-5.46-1.335-5.46-5.925 0-1.305.465-2.385 1.23-3.225-.12-.3-.54-1.53.12-3.18 0 0 1.005-.315 3.3 1.23.96-.27 1.98-.405 3-.405s2.04.135 3 .405c2.295-1.56 3.3-1.23 3.3-1.23.66 1.65.24 2.88.12 3.18.765.84 1.23 1.905 1.23 3.225 0 4.605-2.805 5.625-5.475 5.925.435.375.81 1.095.81 2.22 0 1.605-.015 2.895-.015 3.3 0 .315.225.69.825.57A12.02 12.02 0 0 0 24 12c0-6.63-5.37-12-12-12z"/></svg>
    apache-installer
  </a>

  <div class="footer">
    сделано <a href="https://imiron.ru" target="_blank">imiron.ru</a>
  </div>

</div>
</body>
</html>
