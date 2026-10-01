# Pembuatan file PDF laporan riset (FR-09), pakai reportlab.
#
# Tahap sekarang: 1 template "summary" dulu (sesuai roadmap — versi
# full_report & progress_report menyusul setelah template dasar stabil;
# untuk MVP, ketiga tipe memakai template yang sama dengan judul berbeda).
#
# File PDF disimpan lokal di folder generated_pdfs/ (dibuat otomatis).
# Nanti kalau deploy ke server/cloud, cukup ganti fungsi ini untuk
# menulis ke S3/storage lain — pemanggilnya tidak perlu berubah.

import os
import uuid
from datetime import datetime

from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import cm
from reportlab.lib.colors import HexColor
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer

PDF_DIR = "generated_pdfs"

# Warna sesuai tema aplikasi (navy & emas dari mockup)
NAVY = HexColor("#12181f")
GOLD = HexColor("#d4a24c")

REPORT_TITLES = {
    "summary": "Ringkasan Riset",
    "full_report": "Laporan Lengkap Riset",
    "progress_report": "Laporan Progres Riset",
}


def generate_research_pdf(
    report_type: str,
    research: dict,
    notes: list[dict],
    latest_analysis: dict | None,
) -> str:
    """Buat file PDF dan kembalikan path-nya.

    - research: data riset (title, field, topic, goal, dst)
    - notes: daftar catatan riset
    - latest_analysis: hasil Intelligence terakhir (boleh None kalau belum ada)
    """
    os.makedirs(PDF_DIR, exist_ok=True)
    filename = f"{report_type}_{uuid.uuid4().hex[:8]}.pdf"
    file_path = os.path.join(PDF_DIR, filename)

    doc = SimpleDocTemplate(
        file_path, pagesize=A4,
        leftMargin=2 * cm, rightMargin=2 * cm, topMargin=2 * cm, bottomMargin=2 * cm,
    )

    styles = getSampleStyleSheet()
    style_title = ParagraphStyle("TitleCustom", parent=styles["Title"], textColor=NAVY)
    style_heading = ParagraphStyle("HeadingCustom", parent=styles["Heading2"], textColor=GOLD, spaceBefore=14)
    style_body = styles["BodyText"]

    elements = []

    # --- Kop laporan ---
    elements.append(Paragraph(REPORT_TITLES.get(report_type, "Laporan Riset"), style_title))
    elements.append(Paragraph(
        f"Dibuat: {datetime.now().strftime('%d %B %Y, %H:%M')} · AI Research Companion",
        styles["Normal"],
    ))
    elements.append(Spacer(1, 12))

    # --- Info riset ---
    elements.append(Paragraph("Informasi Riset", style_heading))
    info_rows = [
        ("Judul", research.get("title")),
        ("Bidang", research.get("field")),
        ("Topik", research.get("topic")),
        ("Kata kunci", ", ".join(research.get("keywords") or [])),
        ("Tujuan", research.get("goal")),
        ("Tahap saat ini", research.get("current_stage")),
        ("Progres", f"{research.get('progress_percentage')}%"),
        ("Gaya sitasi", research.get("citation_style")),
    ]
    for label, value in info_rows:
        if value:
            elements.append(Paragraph(f"<b>{label}:</b> {value}", style_body))

    if research.get("abstract"):
        elements.append(Paragraph("Abstrak", style_heading))
        elements.append(Paragraph(research["abstract"], style_body))

    # --- Hasil Intelligence terakhir (kalau ada) ---
    if latest_analysis:
        elements.append(Paragraph("Analisis AI Terakhir", style_heading))
        elements.append(Paragraph(
            f"<b>Skor Kesehatan Riset:</b> {latest_analysis.get('health_score')}/100 · "
            f"<b>Kesiapan Publikasi:</b> {latest_analysis.get('publication_readiness')}/100",
            style_body,
        ))
        if latest_analysis.get("gap_analysis"):
            elements.append(Paragraph(f"<b>Gap Analysis:</b> {latest_analysis['gap_analysis']}", style_body))
        if latest_analysis.get("novelty_assessment"):
            elements.append(Paragraph(f"<b>Novelty:</b> {latest_analysis['novelty_assessment']}", style_body))
        for label, key in (("Kekuatan", "strengths"), ("Kelemahan", "weaknesses"), ("Rekomendasi", "recommendations")):
            items = latest_analysis.get(key) or []
            if items:
                elements.append(Paragraph(f"<b>{label}:</b>", style_body))
                for item in items:
                    elements.append(Paragraph(f"• {item}", style_body))

    # --- Catatan riset ---
    if notes:
        elements.append(Paragraph(f"Catatan Riset ({len(notes)})", style_heading))
        for note in notes:
            elements.append(Paragraph(f"<b>[{note['type']}] {note['title']}</b>", style_body))
            if note.get("content"):
                # Batasi panjang isi catatan di laporan ringkasan biar rapi
                content = note["content"][:600]
                elements.append(Paragraph(content, style_body))
            elements.append(Spacer(1, 6))

    doc.build(elements)
    return file_path