def html_escape(s):
    return (s or "").replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")

rows = []
rows.append("<table><tbody>")
rows.append("<tr><th>User</th><th>Pages (title – createdDate)</th><th>Total</th></tr>")

for user, pages in sorted(by_user.items(), key=lambda kv: (-len(kv[1]), kv[0].lower())):
    page_lines = [f"{html_escape(t)} – {d}" for t, d in pages]
    pages_cell = "<br/>".join(page_lines) if page_lines else ""
    rows.append(
        f"<tr><td>{html_escape(user)}</td><td>{pages_cell}</td><td>{len(pages)}</td></tr>"
    )

rows.append("</tbody></table>")
storage_table = "\n".join(rows)s



payload = {
    "type": "page",
    "title": "User Page Report (Past 30 Days)",
    "space": {"key": "ENG"},      # <-- replace with your space key
    "ancestors": [{"id": 12345}], # optional: parent page ID
    "body": {
        "storage": {
            "value": f"<h2>Users and their pages (last 30 days)</h2>{storage_table}",
            "representation": "storage"
        }
    }
}

resp = session.post(f"{BASE_URL}/rest/api/content/", json=payload)
print(resp.status_code, resp.json())