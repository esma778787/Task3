import React, { useEffect, useMemo, useState } from "react";

// --- Helpers ---------------------------------------------------------------
const STORAGE_KEY = "erasmus-sim-data-v1";

const sampleProjects = [
  {
    id: "p1",
    title: "Gençlik Değişimi: Dijital Beceriler",
    country: "İspanya",
    durationWeeks: 2,
    tags: ["Gençlik", "Dijital Beceriler"],
    requiredSkills: ["ingilizce", "takım çalışması"],
  },
  {
    id: "p2",
    title: "ESC: Sürdürülebilirlik ve Doğa",
    country: "Polonya",
    durationWeeks: 8,
    tags: ["Gönüllülük", "Çevre"],
    requiredSkills: ["gönüllülük", "topluluk çalışması"],
  },
  {
    id: "p3",
    title: "Staj: Web Geliştirme",
    country: "Almanya",
    durationWeeks: 12,
    tags: ["Staj", "Web"],
    requiredSkills: ["javascript", "git"],
  },
];

function saveToLocal(data) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
}
function loadFromLocal() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw ? JSON.parse(raw) : null;
  } catch {
    return null;
  }
}

function downloadJson(filename, data) {
  const blob = new Blob([JSON.stringify(data, null, 2)], { type: "application/json" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}

// Basit bir skorlayıcı: eşleşen beceriler + dil seviyesi + deneyim süresi
function computeScore(state) {
  const project = sampleProjects.find((p) => p.id === state.projectId);
  if (!project) return 0;
  let score = 0;
  // Skills match
  const userSkills = (state.skills || []).map((s) => s.toLowerCase().trim());
  for (const req of project.requiredSkills) {
    if (userSkills.includes(req)) score += 20; // her eşleşme 20 puan
  }
  // English level
  const levelMap = { beginner: 5, intermediate: 10, advanced: 15, native: 20 };
  score += levelMap[state.englishLevel || "beginner"] || 0;
  // Experience months (max 20 puan)
  const exp = Math.min(20, Number(state.experienceMonths || 0));
  score += exp;
  // Motivation quality (heuristic: length)
  const ml = (state.motivation || "").trim();
  score += Math.min(25, Math.floor(ml.length / 120));
  return Math.min(100, score);
}

function genMotivation({ name, projectId, goals, strengths }) {
  const project = sampleProjects.find((p) => p.id === projectId);
  const pTitle = project ? `${project.title} (${project.country})` : "seçtiğim proje";
  return `Sayın Yetkili,\n\nBen ${name || "[İsminiz]"}, ${pTitle} programına katılmak istiyorum. \n${
    goals ||
    "Bu proje sayesinde hem kişisel gelişimimi desteklemek hem de uluslararası bir ortamda öğrenme fırsatı yakalamak istiyorum."
  } \n\nGüçlü yönlerim: ${
    strengths || "takım çalışması, sorumluluk bilinci ve yeni teknolojilere hızlı uyum"
  }. Proje kapsamında edineceğim deneyimlerle topluluğuma katkı sunmayı ve öğrendiklerimi paylaşmayı hedefliyorum.\n\nDeğerlendirmeniz için teşekkür ederim.\nSaygılarımla,\n${name || "[İsminiz]"}`;
}

// --- UI atoms --------------------------------------------------------------
function StepHeader({ step, total, title }) {
  return (
    <div className="mb-4">
      <div className="flex items-center justify-between">
        <h2 className="text-xl font-semibold">{title}</h2>
        <span className="text-sm opacity-70">Adım {step} / {total}</span>
      </div>
      <div className="w-full h-2 bg-gray-200 rounded-full mt-2">
        <div
          className="h-2 bg-indigo-500 rounded-full transition-all"
          style={{ width: `${(step / total) * 100}%` }}
        />
      </div>
    </div>
  );
}

function Chip({ children, selected, onClick }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={
        "px-3 py-1 rounded-full border text-sm mr-2 mb-2 " +
        (selected ? "bg-indigo-600 text-white border-indigo-600" : "hover:bg-gray-100")
      }
    >
      {children}
    </button>
  );
}

// --- Main component --------------------------------------------------------
export default function ErasmusSimulatorApp() {
  const [step, setStep] = useState(1);
  const totalSteps = 5;
  const [state, setState] = useState(() =>
    loadFromLocal() || {
      projectId: "",
      name: "",
      email: "",
      englishLevel: "intermediate",
      experienceMonths: 0,
      skills: [],
      goals: "",
      strengths: "",
      motivation: "",
    }
  );

  useEffect(() => {
    saveToLocal(state);
  }, [state]);

  const selectedProject = useMemo(
    () => sampleProjects.find((p) => p.id === state.projectId) || null,
    [state.projectId]
  );

  // Step components
  const Step1Project = () => (
    <div className="space-y-4">
      <StepHeader step={1} total={totalSteps} title="Proje Seçimi" />
      <div className="grid md:grid-cols-3 gap-4">
        {sampleProjects.map((p) => (
          <div
            key={p.id}
            className={
              "p-4 rounded-2xl border shadow-sm cursor-pointer transition-all " +
              (state.projectId === p.id ? "border-indigo-500 ring-2 ring-indigo-200" : "hover:shadow-md")
            }
            onClick={() => setState((s) => ({ ...s, projectId: p.id }))}
          >
            <div className="text-lg font-medium">{p.title}</div>
            <div className="text-sm opacity-70">{p.country} · {p.durationWeeks} hafta</div>
            <div className="mt-2">
              {p.tags.map((t) => (
                <span key={t} className="inline-block text-xs bg-gray-100 px-2 py-1 rounded mr-2 mb-2">{t}</span>
              ))}
            </div>
            <div className="text-xs opacity-70 mt-2">Gerekli: {p.requiredSkills.join(", ")}</div>
          </div>
        ))}
      </div>
      <div className="flex justify-between mt-4">
        <div />
        <button
          className="px-4 py-2 rounded-xl bg-indigo-600 text-white disabled:opacity-50"
          onClick={() => setStep(2)}
          disabled={!state.projectId}
        >
          Devam
        </button>
      </div>
    </div>
  );

  const Step2Personal = () => (
    <div className="space-y-4">
      <StepHeader step={2} total={totalSteps} title="Kişisel Bilgiler" />
      <div className="grid md:grid-cols-2 gap-4">
        <div>
          <label className="text-sm">İsim Soyisim</label>
          <input
            className="w-full mt-1 px-3 py-2 rounded-xl border"
            value={state.name}
            onChange={(e) => setState((s) => ({ ...s, name: e.target.value }))}
            placeholder="Esma Kula"
          />
        </div>
        <div>
          <label className="text-sm">E-posta</label>
          <input
            className="w-full mt-1 px-3 py-2 rounded-xl border"
            value={state.email}
            onChange={(e) => setState((s) => ({ ...s, email: e.target.value }))}
            placeholder="ornek@mail.com"
            type="email"
          />
        </div>
        <div>
          <label className="text-sm">İngilizce Seviyesi</label>
          <select
            className="w-full mt-1 px-3 py-2 rounded-xl border"
            value={state.englishLevel}
            onChange={(e) => setState((s) => ({ ...s, englishLevel: e.target.value }))}
          >
            <option value="beginner">Beginner</option>
            <option value="intermediate">Intermediate</option>
            <option value="advanced">Advanced</option>
            <option value="native">Native/Bilingual</option>
          </select>
        </div>
        <div>
          <label className="text-sm">İlgili Deneyim (Ay)</label>
          <input
            className="w-full mt-1 px-3 py-2 rounded-xl border"
            value={state.experienceMonths}
            onChange={(e) =>
              setState((s) => ({ ...s, experienceMonths: Math.max(0, Number(e.target.value || 0)) }))
            }
            type="number"
            min={0}
          />
        </div>
      </div>
      <div className="flex justify-between mt-4">
        <button className="px-4 py-2 rounded-xl border" onClick={() => setStep(1)}>Geri</button>
        <button className="px-4 py-2 rounded-xl bg-indigo-600 text-white" onClick={() => setStep(3)}>Devam</button>
      </div>
    </div>
  );

  const allSkills = [
    "javascript",
    "flutter",
    "python",
    "git",
    "ingilizce",
    "takım çalışması",
    "gönüllülük",
    "topluluk çalışması",
    "agile",
  ];

  const Step3Skills = () => (
    <div className="space-y-4">
      <StepHeader step={3} total={totalSteps} title="Beceriler & Hedefler" />
      <div>
        <div className="text-sm mb-2">Beceriler (seçiniz):</div>
        <div>
          {allSkills.map((sk) => (
            <Chip
              key={sk}
              selected={state.skills.includes(sk)}
              onClick={() =>
                setState((s) => ({
                  ...s,
                  skills: s.skills.includes(sk)
                    ? s.skills.filter((x) => x !== sk)
                    : [...s.skills, sk],
                }))
              }
            >
              {sk}
            </Chip>
          ))}
        </div>
      </div>
      <div className="grid md:grid-cols-2 gap-4">
        <div>
          <label className="text-sm">Hedeflerin</label>
          <textarea
            className="w-full mt-1 px-3 py-2 rounded-xl border min-h-[100px]"
            value={state.goals}
            onChange={(e) => setState((s) => ({ ...s, goals: e.target.value }))}
            placeholder="Proje ile neler amaçlıyorsun?"
          />
        </div>
        <div>
          <label className="text-sm">Güçlü Yönlerin</label>
          <textarea
            className="w-full mt-1 px-3 py-2 rounded-xl border min-h-[100px]"
            value={state.strengths}
            onChange={(e) => setState((s) => ({ ...s, strengths: e.target.value }))}
            placeholder="Örn: problem çözme, iletişim, liderlik"
          />
        </div>
      </div>
      <div className="flex justify-between mt-4">
        <button className="px-4 py-2 rounded-xl border" onClick={() => setStep(2)}>Geri</button>
        <button className="px-4 py-2 rounded-xl bg-indigo-600 text-white" onClick={() => setStep(4)}>Devam</button>
      </div>
    </div>
  );

  const Step4Motivation = () => (
    <div className="space-y-4">
      <StepHeader step={4} total={totalSteps} title="Motivasyon Mektubu" />
      <div className="flex flex-col md:flex-row gap-4">
        <div className="md:w-1/2">
          <button
            className="px-3 py-2 rounded-xl border mb-3"
            onClick={() => setState((s) => ({ ...s, motivation: genMotivation(s) }))}
          >
            Otomatik Taslak Oluştur
          </button>
          <textarea
            className="w-full px-3 py-2 rounded-xl border min-h-[260px]"
            value={state.motivation}
            onChange={(e) => setState((s) => ({ ...s, motivation: e.target.value }))}
            placeholder="Motivasyon mektubunu yaz..."
          />
          <div className="text-xs opacity-70 mt-2">İpucu: Taslağı düzenleyip kişiselleştir.</div>
        </div>
        <div className="md:w-1/2 p-4 rounded-2xl border bg-gray-50">
          <div className="font-medium mb-2">Özet</div>
          <div className="text-sm">
            <div><span className="opacity-70">Proje:</span> {selectedProject ? selectedProject.title : "-"}</div>
            <div><span className="opacity-70">İsim:</span> {state.name || "-"}</div>
            <div><span className="opacity-70">E-posta:</span> {state.email || "-"}</div>
            <div><span className="opacity-70">Seviye:</span> {state.englishLevel}</div>
            <div><span className="opacity-70">Beceriler:</span> {state.skills.join(", ") || "-"}</div>
          </div>
          <div className="mt-4 text-sm">
            <div className="opacity-70">Önizleme:</div>
            <pre className="whitespace-pre-wrap text-xs mt-1 bg-white p-2 rounded-xl border max-h-[220px] overflow-auto">{state.motivation || "(Henüz taslak yok)"}</pre>
          </div>
        </div>
      </div>
      <div className="flex justify-between mt-4">
        <button className="px-4 py-2 rounded-xl border" onClick={() => setStep(3)}>Geri</button>
        <button className="px-4 py-2 rounded-xl bg-indigo-600 text-white" onClick={() => setStep(5)}>Devam</button>
      </div>
    </div>
  );

  const score = useMemo(() => computeScore(state), [state]);

  const Step5Review = () => (
    <div className="space-y-4">
      <StepHeader step={5} total={totalSteps} title="Değerlendirme & Çıktı" />
      <div className="grid md:grid-cols-3 gap-4">
        <div className="p-4 rounded-2xl border">
          <div className="text-sm opacity-70">Uygunluk Skoru</div>
          <div className="text-3xl font-semibold mt-1">{score}/100</div>
          <div className="text-xs mt-2 opacity-70">
            * Eşleşen beceriler, dil seviyesi, deneyim ayı ve mektup uzunluğu dikkate alınır.
          </div>
        </div>
        <div className="p-4 rounded-2xl border md:col-span-2">
          <div className="text-sm opacity-70">Önerimiz</div>
          <div className="mt-1 text-sm">
            {score >= 75 && (
              <span>
                Skorun oldukça iyi! Başvuru yapmadan önce motivasyon mektubunu projeye özgü örneklerle
                zenginleştir, referanslarını ekle.
              </span>
            )}
            {score >= 50 && score < 75 && (
              <span>
                Fena değil. Projenin gerektirdiği becerilerden eksik olanları eklemeye çalış ve mektubuna somut
                hedefler yaz. Gerekirse İngilizce seviyeni artıracak kısa bir kurs düşün.
              </span>
            )}
            {score < 50 && (
              <span>
                Bazı alanlarda güçlenmen iyi olur. Gerekli becerilerden birkaçını küçük projelerle kazan, gönüllülük
                deneyimi ekle ve motivasyon mektubunu daha detaylı hale getir.
              </span>
            )}
          </div>
        </div>
      </div>

      <div className="p-4 rounded-2xl border">
        <div className="font-medium">Son Kontrol</div>
        <ul className="list-disc ml-5 text-sm mt-2">
          <li>Proje: <strong>{selectedProject ? selectedProject.title : "-"}</strong></li>
          <li>İsim: <strong>{state.name || "-"}</strong></li>
          <li>E-posta: <strong>{state.email || "-"}</strong></li>
          <li>İngilizce: <strong>{state.englishLevel}</strong></li>
          <li>Beceriler: <strong>{state.skills.join(", ") || "-"}</strong></li>
        </ul>
        <div className="mt-3">
          <div className="text-sm opacity-70">Motivasyon Mektubu</div>
          <pre className="whitespace-pre-wrap text-xs mt-1 bg-gray-50 p-2 rounded-xl border max-h-[240px] overflow-auto">{state.motivation || "(Boş)"}</pre>
        </div>
        <div className="flex flex-wrap gap-2 mt-4">
          <button
            className="px-4 py-2 rounded-xl border"
            onClick={() => {
              localStorage.removeItem(STORAGE_KEY);
              setState(loadFromLocal() || {
                projectId: "",
                name: "",
                email: "",
                englishLevel: "intermediate",
                experienceMonths: 0,
                skills: [],
                goals: "",
                strengths: "",
                motivation: "",
              });
              setStep(1);
            }}
          >
            Sıfırla
          </button>
          <button
            className="px-4 py-2 rounded-xl border"
            onClick={() => downloadJson("erasmus-simulasyon.json", { ...state, score })}
          >
            JSON Olarak İndir
          </button>
          <button
            className="px-4 py-2 rounded-xl bg-indigo-600 text-white"
            onClick={() => alert("Simülasyon tamamlandı! (Buraya gerçek başvuru/Paylaşım entegransı eklenebilir)")}
          >
            Simülasyonu Bitir
          </button>
        </div>
      </div>

      <div className="flex justify-between mt-4">
        <button className="px-4 py-2 rounded-xl border" onClick={() => setStep(4)}>Geri</button>
        <button className="px-4 py-2 rounded-xl bg-gray-900 text-white" onClick={() => window.scrollTo({ top: 0, behavior: "smooth" })}>Başa Dön</button>
      </div>
    </div>
  );

  return (
    <div className="min-h-screen bg-white text-gray-900">
      <div className="max-w-5xl mx-auto p-6">
        <header className="mb-6">
          <h1 className="text-2xl md:text-3xl font-bold">Erasmus+ Mini Simülasyon (JS)</h1>
          <p className="text-sm opacity-70 mt-1">
            Proje seç, bilgilerini gir, motivasyon mektubunu oluştur ve anında uygunluk skorunu gör.
          </p>
        </header>

        <main className="space-y-6">
          {step === 1 && <Step1Project />}
          {step === 2 && <Step2Personal />}
          {step === 3 && <Step3Skills />}
          {step === 4 && <Step4Motivation />}
          {step === 5 && <Step5Review />}
        </main>

        <footer className="mt-10 text-xs opacity-60">
          <div>
            * Verilerin tarayıcıda yerel olarak saklanır. İstediğinde "Sıfırla" ile temizleyebilirsin.
          </div>
          <div>
            * API entegrasyonu için: motivasyon mektubunu bir backend servisine POST etmek üzere
            Step4 içinde bir "Gönder" butonu ekleyebilirsin.
          </div>
        </footer>
      </div>
    </div>
  );
}
