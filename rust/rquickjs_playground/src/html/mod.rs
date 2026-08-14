use anyhow::{Result, anyhow};
use scraper::{ElementRef, Html, Selector};
use std::sync::Arc;

/// Rust-backed cheerio-like HTML manipulation API.
///
/// This module provides a minimal, read-only subset of the cheerio API used by
/// Breeze plugins. It is backed by the `scraper` crate, so parsing and selector
/// matching run in native Rust code while the orchestration logic can stay in
/// JavaScript/QuickJS.

/// A parsed HTML document.
#[derive(rquickjs::JsLifetime, Clone)]
pub struct Document {
    html: Arc<Html>,
}

impl Document {
    /// Parse an HTML document from a string.
    pub fn parse(html: &str) -> Self {
        Self {
            html: Arc::new(Html::parse_document(html)),
        }
    }

    /// Select elements matching `selector`.
    pub fn select(&self, selector: &str) -> Result<Selection> {
        let selector = parse_selector(selector)?;
        let nodes: Vec<_> = self.html.select(&selector).map(|el| el.id()).collect();
        Ok(Selection {
            document: Arc::clone(&self.html),
            nodes,
        })
    }
}

/// A set of selected elements within a document.
#[derive(rquickjs::JsLifetime, Clone)]
pub struct Selection {
    document: Arc<Html>,
    nodes: Vec<ego_tree::NodeId>,
}

impl Selection {
    /// Number of selected elements.
    pub fn len(&self) -> usize {
        self.nodes.len()
    }

    /// Whether the selection is empty.
    pub fn is_empty(&self) -> bool {
        self.nodes.is_empty()
    }

    /// Return a new selection containing only the first element, or empty.
    pub fn first(&self) -> Self {
        self.eq(0)
    }

    /// Return a new selection containing only the last element, or empty.
    pub fn last(&self) -> Self {
        self.eq(-1)
    }

    /// Return a new selection containing the element at `index`.
    /// Negative indices count from the end, matching cheerio behavior.
    pub fn eq(&self, index: isize) -> Self {
        let resolved = if index < 0 {
            self.nodes.len().saturating_sub(index.unsigned_abs())
        } else {
            index as usize
        };

        let node = self.nodes.get(resolved).copied();
        Self {
            document: Arc::clone(&self.document),
            nodes: node.into_iter().collect(),
        }
    }

    /// Find descendants matching `selector` within the current selection.
    pub fn find(&self, selector: &str) -> Result<Self> {
        let selector = parse_selector(selector)?;
        let mut nodes = Vec::new();
        let mut seen = std::collections::HashSet::new();

        for root in self.element_refs() {
            for descendant in root.select(&selector) {
                let id = descendant.id();
                if seen.insert(id) {
                    nodes.push(id);
                }
            }
        }

        Ok(Self {
            document: Arc::clone(&self.document),
            nodes,
        })
    }

    /// Return the closest ancestor matching `selector` for each element.
    pub fn closest(&self, selector: &str) -> Result<Self> {
        let selector = parse_selector(selector)?;
        let mut nodes = Vec::new();
        let mut seen = std::collections::HashSet::new();

        for start in self.element_refs() {
            let mut current = start.parent();
            while let Some(parent) = current {
                if let Some(element) = ElementRef::wrap(parent) {
                    if selector.matches(&element) {
                        let id = element.id();
                        if seen.insert(id) {
                            nodes.push(id);
                        }
                        break;
                    }
                }
                current = parent.parent();
            }
        }

        Ok(Self {
            document: Arc::clone(&self.document),
            nodes,
        })
    }

    /// Return the immediate parent of each element.
    pub fn parent(&self) -> Self {
        let mut nodes = Vec::new();
        let mut seen = std::collections::HashSet::new();

        for el in self.element_refs() {
            if let Some(parent) = el.parent() {
                if let Some(element) = ElementRef::wrap(parent) {
                    let id = element.id();
                    if seen.insert(id) {
                        nodes.push(id);
                    }
                }
            }
        }

        Self {
            document: Arc::clone(&self.document),
            nodes,
        }
    }

    /// Return true if any selected element matches the selector.
    pub fn is(&self, selector: &str) -> Result<bool> {
        let selector = parse_selector(selector)?;
        Ok(self.element_refs().any(|el| selector.matches(&el)))
    }

    /// Get the value of an attribute from the first element.
    pub fn attr(&self, name: &str) -> Option<String> {
        self.first_element_ref()?.attr(name).map(String::from)
    }

    /// Get the combined text content of all elements in the selection.
    pub fn text(&self) -> String {
        let mut out = String::new();
        for el in self.element_refs() {
            for text in el.text() {
                out.push_str(text);
            }
        }
        out
    }

    /// Get the inner HTML of the first element.
    pub fn html(&self) -> Option<String> {
        Some(self.first_element_ref()?.inner_html())
    }

    /// Iterate over each selected element as a single-element selection.
    pub fn iter(&self) -> impl Iterator<Item = Selection> + '_ {
        self.nodes.iter().map(|&id| Selection {
            document: Arc::clone(&self.document),
            nodes: vec![id],
        })
    }

    /// Convert the selection to a vector of single-element selections.
    ///
    /// This matches the cheerio `.toArray()` semantics for our use-case: plugin
    /// code typically immediately re-wraps each element with `$(el)`.
    pub fn to_array(&self) -> Vec<Selection> {
        self.iter().collect()
    }

    /// Return the direct children of each element, optionally filtered by a selector.
    pub fn children(&self, selector: Option<&str>) -> Result<Self> {
        let selector = selector.map(parse_selector).transpose()?;
        let mut nodes = Vec::new();
        let mut seen = std::collections::HashSet::new();

        for el in self.element_refs() {
            for child in el.child_elements() {
                if let Some(ref sel) = selector {
                    if !sel.matches(&child) {
                        continue;
                    }
                }
                let id = child.id();
                if seen.insert(id) {
                    nodes.push(id);
                }
            }
        }

        Ok(Self::new(Arc::clone(&self.document), nodes))
    }

    /// Keep only elements that match the selector.
    pub fn filter_by_selector(&self, selector: &str) -> Result<Self> {
        let selector = parse_selector(selector)?;
        let nodes = self
            .element_refs()
            .filter(|el| selector.matches(el))
            .map(|el| el.id())
            .collect();
        Ok(Self::new(Arc::clone(&self.document), nodes))
    }

    /// Keep only elements for which the predicate returns true.
    pub fn filter_by_fn<F>(&self, mut predicate: F) -> Self
    where
        F: FnMut(usize, &Selection) -> bool,
    {
        let mut nodes = Vec::new();
        for (i, sel) in self.iter().enumerate() {
            if predicate(i, &sel) {
                nodes.push(sel.nodes[0]);
            }
        }
        Self::new(Arc::clone(&self.document), nodes)
    }

    /// Return elements that have at least one descendant matching the selector.
    pub fn has(&self, selector: &str) -> Result<Self> {
        let selector = parse_selector(selector)?;
        let mut nodes = Vec::new();
        let mut seen = std::collections::HashSet::new();

        for el in self.element_refs() {
            if el.select(&selector).next().is_some() {
                let id = el.id();
                if seen.insert(id) {
                    nodes.push(id);
                }
            }
        }

        Ok(Self::new(Arc::clone(&self.document), nodes))
    }

    /// Return a slice of the selection, supporting negative indices like JS.
    pub fn slice(&self, start: isize, end: Option<isize>) -> Self {
        let len = self.nodes.len() as isize;
        let resolve = |idx: isize| {
            if idx < 0 {
                (len + idx).max(0) as usize
            } else {
                idx.min(len) as usize
            }
        };

        let start = resolve(start);
        let end = resolve(end.unwrap_or(len));
        let nodes = if start >= end {
            Vec::new()
        } else {
            self.nodes[start..end].to_vec()
        };

        Self::new(Arc::clone(&self.document), nodes)
    }

    /// Return all sibling elements of each element, optionally filtered by a selector.
    pub fn siblings(&self, selector: Option<&str>) -> Result<Self> {
        let selector = selector.map(parse_selector).transpose()?;
        let mut nodes = Vec::new();
        let mut seen = std::collections::HashSet::new();

        for el in self.element_refs() {
            if let Some(parent) = el.parent() {
                for child in parent.children() {
                    if let Some(child_el) = ElementRef::wrap(child) {
                        if child_el.id() == el.id() {
                            continue;
                        }
                        if let Some(ref sel) = selector {
                            if !sel.matches(&child_el) {
                                continue;
                            }
                        }
                        let id = child_el.id();
                        if seen.insert(id) {
                            nodes.push(id);
                        }
                    }
                }
            }
        }

        Ok(Self::new(Arc::clone(&self.document), nodes))
    }

    /// Return the immediate next sibling element of each element, optionally filtered.
    pub fn next(&self, selector: Option<&str>) -> Result<Self> {
        let selector = selector.map(parse_selector).transpose()?;
        let mut nodes = Vec::new();
        let mut seen = std::collections::HashSet::new();

        for el in self.element_refs() {
            if let Some(sib) = next_element_sibling(el) {
                if let Some(ref sel) = selector {
                    if !sel.matches(&sib) {
                        continue;
                    }
                }
                let id = sib.id();
                if seen.insert(id) {
                    nodes.push(id);
                }
            }
        }

        Ok(Self::new(Arc::clone(&self.document), nodes))
    }

    /// Return the immediate previous sibling element of each element, optionally filtered.
    pub fn prev(&self, selector: Option<&str>) -> Result<Self> {
        let selector = selector.map(parse_selector).transpose()?;
        let mut nodes = Vec::new();
        let mut seen = std::collections::HashSet::new();

        for el in self.element_refs() {
            if let Some(sib) = prev_element_sibling(el) {
                if let Some(ref sel) = selector {
                    if !sel.matches(&sib) {
                        continue;
                    }
                }
                let id = sib.id();
                if seen.insert(id) {
                    nodes.push(id);
                }
            }
        }

        Ok(Self::new(Arc::clone(&self.document), nodes))
    }

    /// Return the index of the first element among its parent's children, or None.
    pub fn index(&self) -> Option<usize> {
        let el = self.first_element_ref()?;
        let parent = el.parent()?;
        parent
            .children()
            .filter_map(ElementRef::wrap)
            .position(|child| child.id() == el.id())
    }

    /// Read the form value of the first element (input/textarea/select).
    pub fn val(&self) -> Option<String> {
        let el = self.first_element_ref()?;
        let tag = el.value().name().to_ascii_lowercase();

        match tag.as_str() {
            "input" => {
                let ty = el.attr("type").unwrap_or("").to_ascii_lowercase();
                if ty == "checkbox" || ty == "radio" {
                    el.attr("checked")
                        .map(|_| el.attr("value").unwrap_or("on").to_string())
                } else {
                    el.attr("value").map(String::from)
                }
            }
            "textarea" => Some(el.text().collect()),
            "select" => {
                let selected = el
                    .select(&Selector::parse("option[selected]").expect("static selector"))
                    .next()
                    .or_else(|| {
                        el.select(&Selector::parse("option").expect("static selector"))
                            .next()
                    })?;
                selected
                    .attr("value")
                    .map(String::from)
                    .or_else(|| Some(selected.text().collect()))
            }
            _ => el.attr("value").map(String::from),
        }
    }

    pub(crate) fn new(document: Arc<Html>, nodes: Vec<ego_tree::NodeId>) -> Self {
        Self { document, nodes }
    }

    fn first_element_ref(&self) -> Option<ElementRef<'_>> {
        self.nodes
            .first()
            .and_then(|id| self.document.tree.get(*id).and_then(ElementRef::wrap))
    }

    fn element_refs(&self) -> impl Iterator<Item = ElementRef<'_>> + '_ {
        self.nodes
            .iter()
            .filter_map(|&id| self.document.tree.get(id).and_then(ElementRef::wrap))
    }
}

fn parse_selector(selector: &str) -> Result<Selector> {
    Selector::parse(selector)
        .map_err(|err| anyhow!("invalid CSS selector '{}': {:?}", selector, err))
}

fn next_element_sibling(el: ElementRef<'_>) -> Option<ElementRef<'_>> {
    let mut node = el.next_sibling();
    while let Some(n) = node {
        if let Some(elem) = ElementRef::wrap(n) {
            return Some(elem);
        }
        node = n.next_sibling();
    }
    None
}

fn prev_element_sibling(el: ElementRef<'_>) -> Option<ElementRef<'_>> {
    let mut node = el.prev_sibling();
    while let Some(n) = node {
        if let Some(elem) = ElementRef::wrap(n) {
            return Some(elem);
        }
        node = n.prev_sibling();
    }
    None
}

impl<'js> rquickjs::class::Trace<'js> for Document {
    fn trace<'a>(&self, _tracer: rquickjs::class::Tracer<'a, 'js>) {}
}

impl<'js> rquickjs::class::Trace<'js> for Selection {
    fn trace<'a>(&self, _tracer: rquickjs::class::Tracer<'a, 'js>) {}
}

pub mod js_binding;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn basic_select_attr_text() {
        let doc = Document::parse(
            r#"<html><body><h2 class="title" data-id="42">Hello world</h2></body></html>"#,
        );
        let sel = doc.select("h2.title").unwrap();
        assert_eq!(sel.len(), 1);
        assert_eq!(sel.attr("data-id"), Some("42".to_string()));
        assert_eq!(sel.text(), "Hello world");
    }

    #[test]
    fn find_and_first() {
        let doc = Document::parse(
            r#"
            <ul>
                <li><a href="/a">A</a></li>
                <li><a href="/b">B</a></li>
            </ul>
        "#,
        );
        let links = doc.select("li").unwrap().find("a").unwrap();
        assert_eq!(links.len(), 2);
        assert_eq!(links.first().attr("href"), Some("/a".to_string()));
    }

    #[test]
    fn eq_with_negative_index() {
        let doc = Document::parse(r#"<ul><li>1</li><li>2</li><li>3</li></ul>"#);
        let items = doc.select("li").unwrap();
        assert_eq!(items.eq(-1).text(), "3");
        assert_eq!(items.eq(-2).text(), "2");
        assert_eq!(items.eq(0).text(), "1");
    }

    #[test]
    fn to_array_can_be_rewrapped() {
        let doc = Document::parse(r#"<ul><li>a</li><li>b</li></ul>"#);
        let items = doc.select("li").unwrap().to_array();
        assert_eq!(items.len(), 2);
        assert_eq!(items[0].text(), "a");
        assert_eq!(items[1].text(), "b");
    }

    #[test]
    fn children_only_direct_descendants() {
        let doc = Document::parse(r#"<ul><li><a>a</a></li><li><b>b</b><span>x</span></li></ul>"#);
        let items = doc.select("li").unwrap();
        assert_eq!(items.children(None).unwrap().len(), 3);
        assert_eq!(items.children(Some("span")).unwrap().text(), "x");
    }

    #[test]
    fn filter_keeps_matching_elements() {
        let doc =
            Document::parse(r#"<ul><li class="hot">A</li><li>B</li><li class="hot">C</li></ul>"#);
        let items = doc.select("li").unwrap();
        assert_eq!(items.filter_by_selector(".hot").unwrap().len(), 2);
        assert_eq!(items.filter_by_fn(|_, sel| sel.text() == "B").text(), "B");
    }

    #[test]
    fn has_selects_parents_with_descendant() {
        let doc = Document::parse(
            r#"<div class="card"><img src="a.jpg"></div><div class="card"><span>text</span></div>"#,
        );
        let cards = doc.select(".card").unwrap();
        assert_eq!(cards.has("img").unwrap().len(), 1);
    }

    #[test]
    fn slice_supports_negative_indices() {
        let doc = Document::parse(r#"<ul><li>1</li><li>2</li><li>3</li><li>4</li></ul>"#);
        let items = doc.select("li").unwrap();
        assert_eq!(items.slice(1, Some(3)).text(), "23");
        assert_eq!(items.slice(-2, None).text(), "34");
        assert_eq!(items.slice(2, Some(-1)).text(), "3");
        assert!(items.slice(2, Some(2)).is_empty());
    }

    #[test]
    fn siblings_next_prev() {
        let doc = Document::parse(
            r#"<ul><li class="a">A</li><li class="b">B</li><li class="c">C</li></ul>"#,
        );
        let b = doc.select(".b").unwrap();
        assert_eq!(b.next(None).unwrap().text(), "C");
        assert_eq!(b.prev(None).unwrap().text(), "A");
        assert_eq!(b.siblings(None).unwrap().text(), "AC");
        assert_eq!(b.siblings(Some(".a")).unwrap().text(), "A");
    }

    #[test]
    fn index_reports_position() {
        let doc = Document::parse(r#"<ul><li>A</li><li class="target">B</li><li>C</li></ul>"#);
        let target = doc.select(".target").unwrap();
        assert_eq!(target.index(), Some(1));
        assert_eq!(doc.select("ul").unwrap().index(), Some(0));
    }

    #[test]
    fn val_reads_form_values() {
        let input = Document::parse(r#"<input type="text" value="hello">"#);
        assert_eq!(
            input.select("input").unwrap().val(),
            Some("hello".to_string())
        );

        let checked = Document::parse(r#"<input type="checkbox" checked value="agree">"#);
        assert_eq!(
            checked.select("input").unwrap().val(),
            Some("agree".to_string())
        );

        let unchecked = Document::parse(r#"<input type="checkbox" value="agree">"#);
        assert_eq!(unchecked.select("input").unwrap().val(), None);

        let select = Document::parse(
            r#"<select><option value="1">one</option><option value="2" selected>two</option></select>"#,
        );
        assert_eq!(
            select.select("select").unwrap().val(),
            Some("2".to_string())
        );

        let textarea = Document::parse(r#"<textarea>content</textarea>"#);
        assert_eq!(
            textarea.select("textarea").unwrap().val(),
            Some("content".to_string())
        );
    }
}
