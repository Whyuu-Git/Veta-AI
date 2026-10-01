# Logika pemanggilan LLM (Gemini) untuk Mentor AI & Intelligence.
#
# Fitur tool use (FR-07a): fungsi search_journals didaftarkan sebagai "tool"
# ke Gemini. SDK google-genai otomatis menjalankan fungsi Python yang kita
# kasih saat model memintanya (automatic function calling), lalu hasilnya
# dikirim balik ke model untuk disusun jadi jawaban — kita tidak perlu
# menulis loop tool-use manual.

import json

from google import genai
from google.genai import types
from app.core.config import settings
from app.services import journal_search_service

MODEL_NAME = "gemini-flash-lite-latest"


class LlmService:
    def __init__(self):
        self.client = genai.Client(api_key=settings.llm_api_key)

    def generate_reply(
        self,
        user_message: str,
        research_context: dict | None = None,
        chat_history: list[dict] | None = None,
    ) -> tuple[str, list[dict]]:
        """
        Kirim pesan ke Gemini, dapatkan balasan + daftar jurnal yang
        ditemukan lewat tool use (kosong kalau model tidak mencari jurnal).
        """

        # Menampung hasil pencarian selama satu pemanggilan ini,
        # supaya router bisa menyimpannya ke database & menautkan sitasi
        found_journals: list[dict] = []

        def search_journals(query: str) -> list[dict]:
            """Cari jurnal/paper akademik nyata di database literatur eksternal.

            WAJIB dipakai setiap kali pengguna butuh referensi, literatur,
            paper, atau bukti penelitian sebelumnya. Hasil fungsi ini adalah
            SATU-SATUNYA sumber sitasi yang boleh kamu sebutkan.

            Args:
                query: kata kunci bahasa Inggris, spesifik, 3-6 kata,
                    gabungan topik + metode. Contoh bagus:
                    "academic stress detection NLP students".
                    Contoh buruk (terlalu umum): "machine learning".
            """
            results = journal_search_service.search_journals(query)
            found_journals.extend(results)
            return results

        system_instruction = self._build_system_instruction(research_context)

        gemini_history = []
        if chat_history:
            for msg in chat_history:
                role = "model" if msg["role"] == "assistant" else "user"
                gemini_history.append(
                    types.Content(role=role, parts=[types.Part(text=msg["content"])])
                )

        chat = self.client.chats.create(
            model=MODEL_NAME,
            config=types.GenerateContentConfig(
                system_instruction=system_instruction,
                tools=[search_journals],  # <- di sinilah tool didaftarkan
            ),
            history=gemini_history,
        )

        response = chat.send_message(user_message)
        return response.text, found_journals

    def generate_intelligence_analysis(self, research_data: dict) -> dict:
        """
        Analisis AI atas satu proyek riset (FR-08). Mengembalikan dict dengan
        kunci: health_score, publication_readiness, gap_analysis,
        novelty_assessment, strengths, weaknesses, recommendations.

        Kuncinya di sini: response_mime_type="application/json" memaksa Gemini
        membalas JSON murni (tanpa teks pembuka atau ```json), jadi bisa
        langsung di-json.loads tanpa pembersihan.
        """

        prompt = (
            "Analisis proyek riset akademik berikut secara objektif dan kritis.\n\n"
            f"Judul: {research_data.get('title')}\n"
            f"Bidang: {research_data.get('field') or '-'}\n"
            f"Topik: {research_data.get('topic') or '-'}\n"
            f"Kata kunci: {', '.join(research_data.get('keywords') or []) or '-'}\n"
            f"Tujuan: {research_data.get('goal') or '-'}\n"
            f"Abstrak: {research_data.get('abstract') or '-'}\n"
            f"Tahap saat ini: {research_data.get('current_stage')}\n"
            f"Progres: {research_data.get('progress_percentage')}%\n\n"
            "Balas HANYA dengan objek JSON valid berstruktur persis seperti ini:\n"
            "{\n"
            '  "health_score": <int 0-100, kesehatan riset keseluruhan: kejelasan '
            "arah, kelengkapan informasi, kesesuaian tahap dengan progres>,\n"
            '  "publication_readiness": <int 0-100, seberapa siap dipublikasikan '
            "di jurnal ilmiah saat ini>,\n"
            '  "gap_analysis": "<2-4 kalimat: celah/kekurangan informasi atau '
            'metodologi yang perlu diisi>",\n'
            '  "novelty_assessment": "<2-4 kalimat: penilaian kebaruan topik '
            'dibanding arah riset umum di bidangnya>",\n'
            '  "strengths": ["<kekuatan 1>", "<kekuatan 2>", "..."],\n'
            '  "weaknesses": ["<kelemahan 1>", "<kelemahan 2>", "..."],\n'
            '  "recommendations": ["<rekomendasi konkret 1>", "<rekomendasi 2>", "..."]\n'
            "}\n\n"
            "Semua teks dalam bahasa Indonesia. Nilai skor harus jujur — riset "
            "yang informasinya masih minim layak mendapat skor rendah. Jangan "
            "menambahkan kunci lain di luar struktur di atas."
        )

        response = self.client.models.generate_content(
            model=MODEL_NAME,
            contents=prompt,
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
            ),
        )

        data = json.loads(response.text)

        # Pengaman: pastikan skor dalam rentang 0-100 walau model "kreatif"
        for key in ("health_score", "publication_readiness"):
            value = data.get(key)
            if isinstance(value, (int, float)):
                data[key] = max(0, min(100, int(value)))
            else:
                data[key] = None

        return data

    def _build_system_instruction(self, research_context: dict | None) -> str:
        base_instruction = (
            "Kamu adalah Mentor AI di aplikasi AI Research Companion, mendampingi "
            "mahasiswa/dosen/peneliti dalam proses riset akademik mereka. Beri "
            "panduan yang konkret dan relevan dengan konteks riset yang sedang "
            "aktif, bukan jawaban generik.\n\n"
            "ATURAN PENCARIAN LITERATUR (WAJIB DIPATUHI):\n"
            "1. Saat pengguna butuh referensi/literatur/jurnal/paper, WAJIB pakai "
            "tool search_journals. Tulis query dalam bahasa Inggris, spesifik, "
            "3-6 kata yang menggabungkan topik + metode (contoh: 'academic stress "
            "detection natural language processing', BUKAN 'machine learning').\n"
            "2. Setelah hasil tool kembali, SARING: hanya sebutkan paper yang "
            "benar-benar relevan dengan pertanyaan pengguna dan konteks risetnya. "
            "Paper yang melenceng topik JANGAN disebut sama sekali.\n"
            "3. Kalau hasil pencarian pertama kurang relevan, panggil "
            "search_journals lagi dengan query berbeda yang lebih spesifik "
            "(maksimal 3 kali pencarian per pertanyaan).\n"
            "4. DILARANG KERAS menyebut judul paper, nama penulis, DOI, atau tahun "
            "yang TIDAK berasal dari hasil tool search_journals di percakapan ini. "
            "Mengarang sitasi dari ingatanmu adalah pelanggaran serius — sitasi "
            "palsu bisa mencelakakan riset pengguna. Kalau setelah 3 pencarian "
            "tetap tidak ada hasil relevan, katakan jujur bahwa belum ketemu, "
            "dan sarankan kata kunci untuk pencarian mandiri TANPA menyebut "
            "judul paper spesifik.\n"
            "5. Saat menyebut paper dari hasil tool, sertakan judul, penulis, "
            "dan tahun persis seperti yang dikembalikan tool."
        )

        if not research_context:
            return base_instruction

        context_text = (
            f"\n\nKonteks riset yang sedang aktif:\n"
            f"- Judul: {research_context.get('title')}\n"
            f"- Bidang: {research_context.get('field')}\n"
            f"- Tahap saat ini: {research_context.get('current_stage')}\n"
        )
        return base_instruction + context_text