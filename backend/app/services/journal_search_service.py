# Pemanggilan API jurnal eksternal.
# Strategi saat ini: coba Semantic Scholar dulu; kalau gagal (rate limit
# untuk pengakses tanpa API key), otomatis fallback ke OpenAlex yang
# limitnya jauh lebih longgar dan tanpa API key.
# CrossRef & DOAJ menyusul setelah pola ini stabil (sesuai roadmap).

import httpx

SEMANTIC_SCHOLAR_URL = "https://api.semanticscholar.org/graph/v1/paper/search"
OPENALEX_URL = "https://api.openalex.org/works"


def search_journals(query: str, limit: int = 5) -> list[dict]:
    """Fungsi utama yang dipanggil Mentor AI (tool use).
    Coba Semantic Scholar dulu, fallback ke OpenAlex kalau gagal/kosong."""
    results = search_semantic_scholar(query, limit)
    if results:
        return results
    return search_openalex(query, limit)


def search_semantic_scholar(query: str, limit: int = 5) -> list[dict]:
    try:
        response = httpx.get(
            SEMANTIC_SCHOLAR_URL,
            params={
                "query": query,
                "limit": limit,
                "fields": "title,authors,year,abstract,externalIds,url,citationCount",
            },
            timeout=15.0,
        )
        response.raise_for_status()
        data = response.json()
    except httpx.HTTPError as e:
        print(f"[journal_search] Semantic Scholar gagal: {e}")
        return []

    results = []
    for paper in data.get("data", []):
        authors = ", ".join(a.get("name", "") for a in paper.get("authors", [])[:5])
        external_ids = paper.get("externalIds") or {}
        results.append({
            "title": paper.get("title") or "(tanpa judul)",
            "authors": authors,
            "year": paper.get("year"),
            "abstract": (paper.get("abstract") or "")[:1000],
            "doi": external_ids.get("DOI"),
            "url": paper.get("url"),
            "citation_count": paper.get("citationCount") or 0,
            "source": "semantic_scholar",
        })
    return results


def search_openalex(query: str, limit: int = 5) -> list[dict]:
    try:
        response = httpx.get(
            OPENALEX_URL,
            params={
                "search": query,
                "per-page": limit,
                # "relevance_score:desc" = urutkan berdasarkan kecocokan dengan
                # query, bukan berdasarkan popularitas. Tanpa ini, paper super
                # terkenal tapi melenceng topik (misal fluid mechanics) bisa
                # nangkring di urutan atas hanya karena banyak disitasi.
                "sort": "relevance_score:desc",
            },
            timeout=15.0,
        )
        response.raise_for_status()
        data = response.json()
    except httpx.HTTPError as e:
        print(f"[journal_search] OpenAlex gagal: {e}")
        return []

    results = []
    for work in data.get("results", []):
        authors = ", ".join(
            a.get("author", {}).get("display_name", "")
            for a in work.get("authorships", [])[:5]
        )
        doi_url = work.get("doi") or ""
        doi = doi_url.replace("https://doi.org/", "") if doi_url else None

        results.append({
            "title": work.get("display_name") or "(tanpa judul)",
            "authors": authors,
            "year": work.get("publication_year"),
            "abstract": _rebuild_openalex_abstract(work.get("abstract_inverted_index")),
            "doi": doi,
            "url": doi_url or work.get("id"),
            "citation_count": work.get("cited_by_count") or 0,
            "source": "openalex",
        })
    return results


def _rebuild_openalex_abstract(inverted_index: dict | None) -> str:
    """OpenAlex menyimpan abstrak sebagai 'inverted index' (kata -> posisi).
    Fungsi ini menyusunnya kembali jadi teks biasa, dipotong 1000 karakter."""
    if not inverted_index:
        return ""
    positions = {}
    for word, indexes in inverted_index.items():
        for i in indexes:
            positions[i] = word
    text = " ".join(positions[i] for i in sorted(positions))
    return text[:1000]


if __name__ == "__main__":
    # Tes langsung: python -m app.services.journal_search_service
    hasil = search_journals("academic stress detection NLP")
    print(f"Dapat {len(hasil)} hasil")
    for r in hasil:
        print("-", f"[{r['source']}]", r["title"], f"({r['year']})")