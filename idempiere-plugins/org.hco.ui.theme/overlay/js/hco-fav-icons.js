/* SAW033 — distinct icons for Home favourites (My People, Places and Actions) */
(function () {
	'use strict';

	var MAP = [
		{ re: /submitted\s+incident/i, key: 'incident-list' },
		{ re: /incident\s+report/i, key: 'incident' },
		{ re: /support\s+location/i, key: 'location' },
		{ re: /template\s+shift/i, key: 'template' },
		{ re: /unavailability|leave/i, key: 'leave' },
		{ re: /available\s+shift/i, key: 'available' },
		{ re: /^my\s+shifts?$/i, key: 'shifts' },
		{ re: /^client$/i, key: 'client' }
	];

	function keyFor(text) {
		var t = (text || '').replace(/\u00a0/g, ' ').replace(/\+/g, '').trim();
		for (var i = 0; i < MAP.length; i++) {
			if (MAP[i].re.test(t)) return MAP[i].key;
		}
		return 'default';
	}

	function apply() {
		var links = document.querySelectorAll('.dashboard-widget a.menu-href');
		for (var i = 0; i < links.length; i++) {
			var a = links[i];
			var text = (a.textContent || '').replace(/\u00a0/g, ' ').replace(/\+/g, '').trim();
			var key = keyFor(text);
			if (a.getAttribute('data-hco-fav') === key && a.querySelector('i.hco-fav-icon-' + key)) {
				continue;
			}
			a.setAttribute('data-hco-fav', key);
			var icon = a.querySelector('i');
			if (!icon) {
				icon = document.createElement('i');
				a.insertBefore(icon, a.firstChild);
			}
			icon.className = 'hco-fav-icon hco-fav-icon-' + key;
			icon.setAttribute('aria-hidden', 'true');
		}
	}

	function start() {
		apply();
		if (window.MutationObserver) {
			var obs = new MutationObserver(function () { apply(); });
			obs.observe(document.body, { childList: true, subtree: true });
		} else {
			setInterval(apply, 2500);
		}
		if (window.zk && typeof zk.afterMount === 'function') {
			zk.afterMount(function () { apply(); });
		}
	}

	if (document.readyState === 'loading') {
		document.addEventListener('DOMContentLoaded', start);
	} else {
		start();
	}
})();
