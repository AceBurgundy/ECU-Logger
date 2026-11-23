/**
 * @typedef {object} SearchIndexEntry
 * @property {string} title - Navigation item title.
 * @property {string} description - Navigation item description.
 * @property {string} path - Navigation item path.
 * @property {string} [iconName] - Google Symbol icon name.
 */

/** @type {boolean} */
let isSearchModalOpen = false;

/** @type {Set<(isOpen: boolean) => void>} */
const modalStateListeners = new Set();

/** @type {Set<(results: Array<SearchIndexEntry>) => void>} */
const queryResultListeners = new Set();

/** @type {((targetPath: string) => void)|null} */
let itemSelectionHandler = null;

/**
 * Registers an item selection handler callback.
 * @param {(targetPath: string) => void} handler - Item selection handler.
 * @returns {void}
 */
export function setItemSelectionHandler(handler) {
    itemSelectionHandler = handler;
}

/**
 * Dispatches item selection to active handler and closes modal.
 * @param {string} targetPath - Selected navigation path.
 * @returns {void}
 */
export function selectSearchResult(targetPath) {
    closeSearchModal();
    if (typeof itemSelectionHandler === 'function') {
        itemSelectionHandler(targetPath);
    }
}

/**
 * Subscribes a listener to modal open/close state transitions.
 * @param {(isOpen: boolean) => void} listener - State change callback.
 * @returns {() => void} Unsubscribe function.
 */
export function subscribeToModalState(listener) {
    modalStateListeners.add(listener);
    listener(isSearchModalOpen);
    return () => modalStateListeners.delete(listener);
}

/**
 * Subscribes a listener to search query result updates.
 * @param {(results: Array<SearchIndexEntry>) => void} listener - Query results callback.
 * @returns {() => void} Unsubscribe function.
 */
export function subscribeToQueryResults(listener) {
    queryResultListeners.add(listener);
    return () => queryResultListeners.delete(listener);
}

/**
 * Opens the search modal dialog.
 * @returns {void}
 */
export function openSearchModal() {
    isSearchModalOpen = true;
    modalStateListeners.forEach((listener) => listener(true));
    searchDocumentation('');
}

/**
 * Closes the search modal dialog.
 * @returns {void}
 */
export function closeSearchModal() {
    isSearchModalOpen = false;
    modalStateListeners.forEach((listener) => listener(false));
}

/**
 * Toggles search modal open/close state.
 * @returns {void}
 */
export function toggleSearchModal() {
    if (isSearchModalOpen) {
        closeSearchModal();
    } else {
        openSearchModal();
    }
}

/**
 * Extracts searchable plain text from a documentation item's tabs and blocks.
 * @param {object|undefined} itemSpecification - Loaded navigation item specification.
 * @returns {string} Lowercased combined search text.
 */
function buildSearchableText(itemSpecification) {
    if (!itemSpecification || typeof itemSpecification !== 'object') {
        return '';
    }
    /** @type {Array<string>} */
    const chunks = [];
    if (itemSpecification.item_title) chunks.push(String(itemSpecification.item_title));
    if (itemSpecification.header_container?.title) chunks.push(String(itemSpecification.header_container.title));
    if (itemSpecification.header_container?.description) chunks.push(String(itemSpecification.header_container.description));

    const tabs = Array.isArray(itemSpecification.tab_list) ? itemSpecification.tab_list : [];
    tabs.forEach((tab) => {
        if (tab.tab_title) chunks.push(String(tab.tab_title));
        const blocks = Array.isArray(tab.section_blocks) ? tab.section_blocks : [];
        blocks.forEach((block) => {
            if (block.heading_title) chunks.push(String(block.heading_title));
            if (block.paragraph_text) chunks.push(String(block.paragraph_text));
            if (block.description) chunks.push(String(block.description));
            if (Array.isArray(block.table_headers)) chunks.push(block.table_headers.join(' '));
            if (Array.isArray(block.table_rows)) {
                block.table_rows.forEach((row) => {
                    if (Array.isArray(row)) chunks.push(row.join(' '));
                });
            }
            if (Array.isArray(block.diamond_items)) chunks.push(block.diamond_items.join(' '));
            if (Array.isArray(block.cards)) {
                block.cards.forEach((card) => {
                    if (card.title) chunks.push(String(card.title));
                    if (card.description) chunks.push(String(card.description));
                    if (card.label) chunks.push(String(card.label));
                });
            }
        });
    });

    return chunks.join(' ').toLowerCase();
}

/**
 * Checks whether searchable text matches query (supporting simple resize/resizing stem).
 * @param {string} haystack - Lowercased text corpus.
 * @param {string} normalizedQuery - Lowercased trimmed query.
 * @returns {boolean}
 */
function matchesSearchQuery(haystack, normalizedQuery) {
    if (!normalizedQuery) return true;
    if (haystack.includes(normalizedQuery)) return true;
    if (normalizedQuery.length >= 4 && normalizedQuery.endsWith('e')) {
        const stem = normalizedQuery.slice(0, -1);
        if (haystack.includes(`${stem}ing`)) return true;
    }
    return false;
}

/**
 * Queries all available documentation items against a keyword.
 * @param {string} queryText - Search keyword.
 * @returns {Array<SearchIndexEntry>} Matching documentation entries.
 */
export function searchDocumentation(queryText) {
    /** @type {string} */
    const normalizedQuery = (queryText || '').toLowerCase().trim();
    /** @type {Array<SearchIndexEntry>} */
    const matchedEntries = [];

    /** @type {Object|Array<object>} */
    const masterData = window.DOCUMENTATION_DATA || {};
    /** @type {Array<object>} */
    const categoryGroups = Array.isArray(masterData)
        ? masterData
        : (masterData.category_groups || []);
    /** @type {string} */
    const dashboardPath = masterData.dashboard_path || "data/dashboard.js";
    /** @type {Record<string, object>} */
    const documentationItems = window.DOCUMENTATION_ITEMS || {};

    categoryGroups.forEach((group) => {
        /** @type {Array<string>} */
        const itemPaths = group.navigation_item_paths || [];
        itemPaths.forEach((path) => {
            /** @type {object|undefined} */
            const itemSpecification = documentationItems[path];
            /** @type {string} */
            const title = itemSpecification?.item_title || path.split('/').pop()?.replace('.js', '') || '';
            /** @type {string} */
            const description = itemSpecification?.header_container?.description || '';
            /** @type {string} */
            const iconName = itemSpecification?.icon_name || 'article';
            /** @type {string} */
            const corpus = buildSearchableText(itemSpecification) || `${title} ${description}`.toLowerCase();

            if (matchesSearchQuery(corpus, normalizedQuery)) {
                matchedEntries.push({
                    title,
                    description,
                    path,
                    iconName
                });
            }
        });
    });

    // Include dashboard landing page entry if available
    if (documentationItems[dashboardPath]) {
        /** @type {object} */
        const dashboardSpecification = documentationItems[dashboardPath];
        /** @type {string} */
        const dashboardTitle = dashboardSpecification.item_title || "Dashboard";
        /** @type {string} */
        const dashboardDescription = dashboardSpecification.header_container?.description || "";
        /** @type {string} */
        const dashboardIconName = dashboardSpecification.icon_name || "dashboard";
        /** @type {string} */
        const dashboardCorpus = buildSearchableText(dashboardSpecification) || `${dashboardTitle} ${dashboardDescription}`.toLowerCase();

        if (matchesSearchQuery(dashboardCorpus, normalizedQuery)) {
            matchedEntries.push({
                title: dashboardTitle,
                description: dashboardDescription,
                path: dashboardPath,
                iconName: dashboardIconName
            });
        }
    }

    queryResultListeners.forEach((listener) => listener(matchedEntries));
    return matchedEntries;
}

// Global Keyboard Shortcuts (Ctrl+K to open, Escape to close)
window.addEventListener('keydown', (event) => {
    if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 'k') {
        event.preventDefault();
        openSearchModal();
    } else if (event.key === 'Escape' && isSearchModalOpen) {
        event.preventDefault();
        closeSearchModal();
    }
});

// Expose globally for backward compatibility and cross-widget activation
window.openSearchModal = openSearchModal;
window.closeSearchModal = closeSearchModal;
