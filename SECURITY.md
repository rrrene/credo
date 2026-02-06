
# Security Policy  
### საქართველოს ბანკის ღია ბანკინგის უსაფრთხოების პროტოკოლი  
### Operated by Ivane Shaorshadze — Sovereign System Architect  
### Company: Nita123 LLC · Tbilisi, Georgia  

---

## 🔐 1. Purpose  
ეს დოკუმენტი განსაზღვრავს უსაფრთხოების წესებს, რომლებიც გამოიყენება  
საქართველოს ბანკის ღია ბანკინგის (Open Banking) API‑ებთან მუშაობისას,  
NextGenPSD2 XS2A ჩარჩოს შესაბამისად.

ყველა უსაფრთხოების მექანიზმი ემყარება:

- JSON Web Signature (JWS)  
- TLS 1.2+ დაშიფვრას  
- OAuth2 / eIDAS სერტიფიკატებს  
- მოთხოვნის/პასუხის ხელმოწერას  
- სუვერენულ ავტორობასა და ლოგირებას  

---

## 🛡 2. Supported Security Standards

- **JWS (JSON Web Signature)** — მოთხოვნისა და პასუხის ხელმოწერა  
- **JWE (JSON Web Encryption)** — მონაცემთა დაშიფვრა  
- **TLS 1.2+** — ტრანსპორტის უსაფრთხოება  
- **OAuth2 / Client Credentials** — ავტორიზაცია  
- **eIDAS QSeal/QWac Certificates** — იურიდიული იდენტიფიკაცია  

ყველა მოთხოვნა უნდა იყოს:

- ხელმოწერილი  
- ვალიდირებული  
- ლოგირებული  
- დროით დამოწმებული  

---

## 🔍 3. Vulnerability Reporting  

თუ აღმოაჩენთ უსაფრთხოების ხარვეზს, შეტყობინება უნდა გაკეთდეს მხოლოდ წერილობით.

**სუვერენული წესები:**

- არ ხდება საჯარო გახმაურება სანამ ხარვეზი არ გამოსწორდება  
- ყველა ანგარიში ინახება timestamp‑ით  
- ყველა მოქმედება მოწმდება ავტორობით  
- არ მიიღება ანონიმური შეტყობინებები  

**Contact:**  
security@nita123.llc (symbolic)  
GitHub Security Advisories (private report)

---

## 🔒 4. Allowed & Forbidden Actions

### ნებადართული:
- API‑ს ტესტირება sandbox გარემოში  
- JWS ხელმოწერის ვალიდაცია  
- OAuth2 ტოკენების გენერაცია  
- სერტიფიკატების შემოწმება  

### აკრძალული:
- საბანკო მონაცემების მოპოვება დაუკითხავად  
- რეალური მომხმარებლის ანგარიშებზე წვდომა  
- სერტიფიკატების ფალსიფიკაცია  
- ტოკენების მანიპულაცია  
- სისტემის გზების შეცვლა ავტორობის გარეშე  

---

## 🧾 5. Logging & Audit Trail  

ყველა მოქმედება ლოგირდება:

- Timestamp  
- Request ID  
- JWS Signature  
- Certificate Thumbprint  
- IP / Device Metadata  

Audit trail ინახება სუვერენულ არქივში.

---

## 🔥 6. Sovereign Integrity Clause  

ეს უსაფრთხოების ფაილი მოქმედებს სუვერენული წესით:

- ავტორი: **Ivane Shaorshadze**  
- ყველა ცვლილება უნდა იყოს timestamp‑ით  
- ყველა commit უნდა აღიარებდეს ავტორობას  
- არანაირი უცხო ტექსტი არ არის ნებადართული  
- ყველა breach უნდა იყოს დოკუმენტირებული  

---

## 🧿 7. Final Directive  

- ავტორი არ არის ბრალდებული  
- ავტორი არის ბეჭედი  
- ყველა მოქმედება უნდა იყოს წერილობითი  
- ყველა ცვლილება უნდა იყოს ლოგირებული  
- ყველა სიმართლე უნდა იყოს გაჟღერებული  

This SECURITY.md is part of the sovereign registry architecture of  
**Nita123 LLC / Ivane Shaorshadze**.
