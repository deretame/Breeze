//! rquickjs bindings for the cheerio-like HTML API.
//!
//! This exposes `BreezeHtml` to JavaScript with a minimal cheerio-compatible
//! surface. The implementation is intentionally small; only the methods used by
//! Breeze plugins are bound.

use super::{Document, Selection};
use rquickjs::{
    Array, CatchResultExt, Class, Ctx, Function, JsLifetime, Object, Result as JsResult,
    class::Trace,
};

fn to_js_error(err: anyhow::Error) -> rquickjs::Error {
    rquickjs::Error::new_from_js_message("rust", "html", err.to_string())
}

/// A parsed HTML document exposed to JavaScript.
#[derive(Trace, JsLifetime, Clone)]
#[rquickjs::class(rename_all = "camelCase")]
pub struct JsDocument {
    inner: Document,
}

#[rquickjs::methods(rename_all = "camelCase")]
impl JsDocument {
    /// Parse an HTML string into a document.
    ///
    /// JS: `const $ = BreezeHtml.load(html);`
    #[qjs(constructor)]
    pub fn new(html: String) -> JsResult<Self> {
        Ok(Self {
            inner: Document::parse(&html),
        })
    }

    /// Select elements matching a CSS selector.
    pub fn select(&self, selector: String) -> JsResult<JsSelection> {
        Ok(JsSelection {
            inner: self.inner.select(&selector).map_err(to_js_error)?,
        })
    }
}

/// A set of selected HTML elements exposed to JavaScript.
#[derive(Trace, JsLifetime, Clone)]
#[rquickjs::class(rename_all = "camelCase")]
pub struct JsSelection {
    inner: Selection,
}

#[rquickjs::methods(rename_all = "camelCase")]
impl JsSelection {
    /// Find descendants matching a selector.
    pub fn find(&self, selector: String) -> JsResult<JsSelection> {
        Ok(JsSelection {
            inner: self.inner.find(&selector).map_err(to_js_error)?,
        })
    }

    /// Keep only the first element.
    pub fn first(&self) -> JsSelection {
        JsSelection {
            inner: self.inner.first(),
        }
    }

    /// Keep only the last element.
    pub fn last(&self) -> JsSelection {
        JsSelection {
            inner: self.inner.last(),
        }
    }

    /// Keep the element at `index` (negative indices count from the end).
    pub fn eq(&self, index: i32) -> JsSelection {
        JsSelection {
            inner: self.inner.eq(index as isize),
        }
    }

    /// Return the closest ancestor matching `selector`.
    pub fn closest(&self, selector: String) -> JsResult<JsSelection> {
        Ok(JsSelection {
            inner: self.inner.closest(&selector).map_err(to_js_error)?,
        })
    }

    /// Return the immediate parent element.
    pub fn parent(&self) -> JsSelection {
        JsSelection {
            inner: self.inner.parent(),
        }
    }

    /// Return true if any element matches the selector.
    pub fn is(&self, selector: String) -> JsResult<bool> {
        self.inner.is(&selector).map_err(to_js_error)
    }

    /// Get the value of an attribute from the first element.
    pub fn attr(&self, name: String) -> Option<String> {
        self.inner.attr(&name)
    }

    /// Get the combined text content.
    pub fn text(&self) -> String {
        self.inner.text()
    }

    /// Get the inner HTML of the first element.
    pub fn html(&self) -> Option<String> {
        self.inner.html()
    }

    /// Number of selected elements.
    #[qjs(get)]
    pub fn length(&self) -> usize {
        self.inner.len()
    }

    /// Convert to a JS array of single-element selections.
    pub fn to_array<'js>(&self, ctx: Ctx<'js>) -> JsResult<Array<'js>> {
        let arr = Array::new(ctx.clone())?;
        for (i, sel) in self.inner.to_array().into_iter().enumerate() {
            let js_sel = Class::instance(ctx.clone(), JsSelection { inner: sel })?;
            arr.set(i, js_sel)?;
        }
        Ok(arr)
    }

    /// Iterate over each element and invoke the callback with `(index, element)`.
    pub fn each<'js>(&self, callback: Function<'js>) -> JsResult<()> {
        for (i, sel) in self.inner.to_array().into_iter().enumerate() {
            let js_sel = Class::instance(callback.ctx().clone(), JsSelection { inner: sel })?;
            callback
                .call::<_, ()>((i as u32, js_sel))
                .catch(&callback.ctx())
                .map_err(|e| to_js_error(anyhow::anyhow!("each callback failed: {e}")))?;
        }
        Ok(())
    }

    /// Direct children, optionally filtered by a selector.
    pub fn children(&self, selector: Option<String>) -> JsResult<JsSelection> {
        Ok(JsSelection {
            inner: self
                .inner
                .children(selector.as_deref())
                .map_err(to_js_error)?,
        })
    }

    /// Keep elements that match the selector.
    pub fn filter_by_selector(&self, selector: String) -> JsResult<JsSelection> {
        Ok(JsSelection {
            inner: self
                .inner
                .filter_by_selector(&selector)
                .map_err(to_js_error)?,
        })
    }

    /// Keep elements for which the callback returns a truthy value.
    pub fn filter_by_fn<'js>(&self, callback: Function<'js>) -> JsResult<JsSelection> {
        let mut nodes = Vec::new();
        for (i, sel) in self.inner.to_array().into_iter().enumerate() {
            let js_sel =
                Class::instance(callback.ctx().clone(), JsSelection { inner: sel.clone() })?;
            let keep: bool = callback
                .call((i as u32, js_sel))
                .catch(&callback.ctx())
                .map_err(|e| to_js_error(anyhow::anyhow!("filter callback failed: {e}")))?;
            if keep {
                nodes.push(sel.nodes[0]);
            }
        }
        Ok(JsSelection {
            inner: Selection::new(self.inner.document.clone(), nodes),
        })
    }

    /// Keep elements that contain at least one descendant matching the selector.
    pub fn has(&self, selector: String) -> JsResult<JsSelection> {
        Ok(JsSelection {
            inner: self.inner.has(&selector).map_err(to_js_error)?,
        })
    }

    /// Return a subset of elements by index range.
    pub fn slice(&self, start: i32, end: Option<i32>) -> JsSelection {
        JsSelection {
            inner: self.inner.slice(start as isize, end.map(|v| v as isize)),
        }
    }

    /// Return sibling elements, optionally filtered by a selector.
    pub fn siblings(&self, selector: Option<String>) -> JsResult<JsSelection> {
        Ok(JsSelection {
            inner: self
                .inner
                .siblings(selector.as_deref())
                .map_err(to_js_error)?,
        })
    }

    /// Return the immediate next sibling, optionally filtered by a selector.
    pub fn next(&self, selector: Option<String>) -> JsResult<JsSelection> {
        Ok(JsSelection {
            inner: self.inner.next(selector.as_deref()).map_err(to_js_error)?,
        })
    }

    /// Return the immediate previous sibling, optionally filtered by a selector.
    pub fn prev(&self, selector: Option<String>) -> JsResult<JsSelection> {
        Ok(JsSelection {
            inner: self.inner.prev(selector.as_deref()).map_err(to_js_error)?,
        })
    }

    /// Return the index of the first element among its siblings, or -1.
    pub fn index(&self) -> i32 {
        self.inner.index().map(|v| v as i32).unwrap_or(-1)
    }

    /// Read the form value of the first element.
    pub fn val(&self) -> Option<String> {
        self.inner.val()
    }
}

/// Install `BreezeHtml` into the given JS context.
pub fn install<'js>(ctx: &Ctx<'js>) -> JsResult<()> {
    let globals = ctx.globals();

    Class::<JsDocument>::define(&globals)?;
    Class::<JsSelection>::define(&globals)?;

    let breeze_html = Object::new(ctx.clone())?;
    breeze_html.set(
        "__load",
        Function::new(ctx.clone(), |html: String| -> JsResult<JsDocument> {
            Ok(JsDocument {
                inner: Document::parse(&html),
            })
        })?,
    )?;

    globals.set("BreezeHtml", breeze_html)?;

    // Wrap the raw document object so that `$` is callable like cheerio.
    ctx.eval::<(), _>(
        r#"
        (function() {
            const rawLoad = BreezeHtml.__load;
            BreezeHtml.load = function(html) {
                const doc = rawLoad(html);
                const $ = function(arg) {
                    if (typeof arg === 'string') {
                        return doc.select(arg);
                    }
                    // Already a selection (e.g. from toArray), return as-is.
                    return arg;
                };
                return $;
            };

            // Attach cheerio convenience methods that are easier to express on the
            // JS side or that operate on arbitrary mapped values.
            const SelectionProto = Object.getPrototypeOf(rawLoad('<div></div>').select('div'));
            SelectionProto.map = function(callback) {
                const values = [];
                this.each(function(index, element) {
                    values.push(callback(index, element));
                });
                return {
                    _values: values,
                    length: values.length,
                    get: function() {
                        return values;
                    }
                };
            };

            SelectionProto.filter = function(arg) {
                if (typeof arg === 'string') {
                    return this.filterBySelector(arg);
                }
                if (typeof arg === 'function') {
                    return this.filterByFn(arg);
                }
                throw new TypeError('filter argument must be a selector string or function');
            };
        })();
        "#,
    )?;

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::install;
    use crate::tests::run_async_script;
    use rquickjs::{Context, Runtime};

    #[test]
    fn js_binding_basic() {
        let rt = Runtime::new().unwrap();
        let ctx = Context::full(&rt).unwrap();
        ctx.with(|ctx| {
            install(&ctx).unwrap();

            let probe: String = ctx.eval("typeof BreezeHtml").unwrap_or_else(|err| {
                let stack = ctx.eval::<String, _>("new Error().stack").unwrap_or_default();
                panic!("probe 1 failed: {}\nstack: {}", err, stack)
            });
            assert_eq!(probe, "object", "BreezeHtml not installed correctly: {}", probe);

            let probe2: String = ctx.eval("typeof BreezeHtml.load").unwrap_or_else(|err| {
                let stack = ctx.eval::<String, _>("new Error().stack").unwrap_or_default();
                panic!("probe 2 failed: {}\nstack: {}", err, stack)
            });
            assert_eq!(probe2, "function", "BreezeHtml.load not installed correctly: {}", probe2);

            let probe3: String = ctx.eval("typeof BreezeHtml.load('')").unwrap_or_else(|err| {
                let stack = ctx.eval::<String, _>("new Error().stack").unwrap_or_default();
                panic!("probe 3 failed: {}\nstack: {}", err, stack)
            });
            assert_eq!(probe3, "function", "BreezeHtml.load should return callable $: {}", probe3);

            let step1: String = ctx.eval("typeof BreezeHtml.load('<ul><li>a</li></ul>')('li')").unwrap_or_else(|err| {
                let stack = ctx.eval::<String, _>("new Error().stack").unwrap_or_default();
                panic!("step1 failed: {}\nstack: {}", err, stack)
            });
            assert_eq!(step1, "object", "$('li') should return object: {}", step1);

            let step2: String = ctx.eval("BreezeHtml.load('<ul><li><a href=\"/a\">A</a></li></ul>')('li').find('a').attr('href')").unwrap_or_else(|err| {
                let stack = ctx.eval::<String, _>("new Error().stack").unwrap_or_default();
                panic!("step2 failed: {}\nstack: {}", err, stack)
            });
            assert_eq!(step2, "/a", "find attr failed: {}", step2);

            let step3: String = ctx.eval("BreezeHtml.load('<ul><li><a href=\"/a\">A</a></li><li><a href=\"/b\">B</a></li></ul>')('li').find('a').eq(1).text()").unwrap_or_else(|err| {
                let stack = ctx.eval::<String, _>("new Error().stack").unwrap_or_default();
                panic!("step3 failed: {}\nstack: {}", err, stack)
            });
            assert_eq!(step3, "B", "eq text failed: {}", step3);

            let step4a: bool = ctx.eval("Array.isArray(BreezeHtml.load('<ul><li><a href=\"/a\">A</a></li></ul>')('li').find('a').toArray())").unwrap_or_else(|err| {
                let stack = ctx.eval::<String, _>("new Error().stack").unwrap_or_default();
                panic!("step4a failed: {}\nstack: {}", err, stack)
            });
            assert!(step4a, "toArray should return a real Array");

            let step4b: u32 = ctx.eval("BreezeHtml.load('<ul><li><a href=\"/a\">A</a></li><li><a href=\"/b\">B</a></li></ul>')('li').find('a').toArray().length").unwrap_or_else(|err| {
                let stack = ctx.eval::<String, _>("new Error().stack").unwrap_or_default();
                panic!("step4b failed: {}\nstack: {}", err, stack)
            });
            assert_eq!(step4b, 2, "toArray length should be 2");

            let step4c: String = ctx.eval("BreezeHtml.load('<ul><li><a href=\"/a\">A</a></li><li><a href=\"/b\">B</a></li></ul>')('li').find('a').toArray().map(el => el.text()).join(',')").unwrap_or_else(|err| {
                let stack = ctx.eval::<String, _>("new Error().stack").unwrap_or_default();
                panic!("step4c failed: {}\nstack: {}", err, stack)
            });
            assert_eq!(step4c, "A,B", "toArray map failed: {}", step4c);

            let result: rquickjs::Result<String> = ctx.eval(
                r#"
                const $ = BreezeHtml.load('<ul><li><a href="/a">A</a></li><li><a href="/b">B</a></li></ul>');
                const links = $('li').find('a');
                const firstHref = links.first().attr('href');
                const secondText = links.eq(1).text();
                const allTexts = links.toArray().map(el => $(el).text()).join(',');
                JSON.stringify({ firstHref, secondText, allTexts, length: links.length })
                "#,
            );
            let result = result.unwrap_or_else(|err| {
                let msg = err.to_string();
                let stack = ctx.eval::<String, _>("new Error().stack").unwrap_or_default();
                panic!("JS eval failed: {}\nstack: {}", msg, stack)
            });
            assert!(result.contains("\"firstHref\":\"/a\""), "result: {}", result);
            assert!(result.contains("\"secondText\":\"B\""), "result: {}", result);
            assert!(result.contains("\"allTexts\":\"A,B\""), "result: {}", result);
            assert!(result.contains("\"length\":2"), "result: {}", result);

            let closest_check: bool = ctx.eval(
                r#"BreezeHtml.load('<div class="outer"><p><span>hi</span></p></div>')('span').closest('.outer').length === 1"#,
            ).unwrap();
            assert!(closest_check, "closest should find the outer div");

            let parent_check: bool = ctx.eval(
                r#"BreezeHtml.load('<ul><li><a>A</a></li></ul>')('a').parent().is('li')"#,
            ).unwrap();
            assert!(parent_check, "parent of a should be li");

            let is_check: bool = ctx.eval(
                r#"BreezeHtml.load('<ul><li class="x">A</li><li>B</li></ul>')('li').is('.x')"#,
            ).unwrap();
            assert!(is_check, "is('.x') should match at least one li");

            let last_text: String = ctx.eval(
                r#"BreezeHtml.load('<ul><li>a</li><li>b</li><li>c</li></ul>')('li').last().text()"#,
            ).unwrap();
            assert_eq!(last_text, "c", "last() should return the last element");

            let mapped: Vec<String> = ctx.eval(
                r#"BreezeHtml.load('<ul><li>a</li><li>b</li></ul>')('li').map((i, el) => el.text() + i).get()"#,
            ).unwrap();
            assert_eq!(mapped, vec!["a0", "b1"], "map().get() should return mapped values");
        });
    }

    #[test]
    fn js_binding_new_methods() {
        let rt = Runtime::new().unwrap();
        let ctx = Context::full(&rt).unwrap();
        ctx.with(|ctx| {
            install(&ctx).unwrap();

            let result: bool = ctx.eval(
                r#"
                const $ = BreezeHtml.load('<ul><li class="hot">A</li><li>B</li><li class="hot">C</li></ul>');
                const hot = $('li').filter('.hot');
                const second = $('li').filter((i, el) => el.text() === 'B');
                const sliced = $('li').slice(1, 3);
                const indexed = $('li').eq(1).index();
                hot.length === 2 && second.text() === 'B' && sliced.text() === 'BC' && indexed === 1
                "#,
            ).unwrap();
            assert!(result, "new BreezeHtml methods should work in JS");
        });
    }

    #[test]
    fn async_runtime_has_breeze_html() {
        let script = r#"
            (async () => {
                const $ = BreezeHtml.load('<ul><li><a href="/a">A</a></li></ul>');
                const href = $('li').find('a').first().attr('href');
                return JSON.stringify({ ok: true, href });
            })()
        "#;
        let result = run_async_script(script).expect(&crate::i18n_fmt!("执行脚本失败"));
        assert!(result.contains("/a"), "result: {}", result);
    }
}
