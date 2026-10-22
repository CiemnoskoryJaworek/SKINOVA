# SKINOVA — WHOOPS! (wersja do pierwszego wdrożenia)

W ZIP-ie jest komplet kodu strony, obraz WHOOPS!, 10 obrazów skinów i SQL. Publiczna nazwa strony to **SKINOVA**. Skrzynka WHOOPS! kosztuje **400 wirtualnych monet** (to nie są złotówki; brak prawdziwych płatności).

## KROK 1 — Supabase (konieczne do logowania i otwierania)
1. Wejdź do swojego projektu SKINOVA w Supabase.
2. Otwórz SQL Editor, utwórz New query, wklej CAŁĄ zawartość `supabase.sql`, kliknij Run. Ten skrypt jest przeznaczony dla nowego projektu bez wcześniej uruchomionego schematu SKINOVA.
3. W Supabase → Project Settings → API (lub Connect → API Keys) skopiuj **Project URL** i **publishable/anon key**.
4. Otwórz plik `config.js` na komputerze i wstaw te dwie wartości. Nie umieszczaj tam hasła bazy ani `service_role`/secret key. Klucz anon jest publiczny.
5. W Supabase → Authentication → URL Configuration ustaw Site URL na końcowy adres strony w Vercel (możesz zrobić to po wdrożeniu). Włącz potwierdzanie e-mail i skonfiguruj wysyłkę wiadomości, jeśli planujesz publiczne rejestracje.

## KROK 2 — GitHub
1. Rozpakuj ZIP.
2. Wejdź do pustego repozytorium SKINOVA. Kliknij **uploading an existing file**.
3. Przeciągnij ZAWARTOŚĆ rozpakowanego folderu, zachowując foldery `images/cases` i `images/skins`. Uwaga: webowy upload GitHub może wymagać przeciągnięcia całego folderu lub osobnego dodania folderów.
4. Sprawdź, czy w głównym katalogu repozytorium są `index.html`, `app.js`, `style.css`, `config.js`, `catalog.json`, `supabase.sql` oraz folder `images`.
5. Kliknij **Commit changes**.

## KROK 3 — Vercel
1. Na Vercel wybierz Add New → Project → Import Git Repository → SKINOVA.
2. Framework: Other, Root Directory: `./`, Build Command: puste, Output Directory: domyślne. Kliknij Deploy.
3. W Supabase → Authentication → URL Configuration dodaj końcowy adres Vercel.
4. Zarejestruj konto testowe i sprawdź saldo, bonus i otwarcie WHOOPS!.

## Co działa
- Logowanie/rejestracja Supabase e-mail + hasło, sesja
- 1000 monet na start, 250 bonusu raz dziennie wg UTC
- WHOOPS! za 400 monet, 10 skinów z przesłanymi zdjęciami
- Losowanie po stronie bazy, animacja po stronie przeglądarki
- Ekwipunek, historia, ranking
- Brak wpłat, wypłat, handlu i realnych przedmiotów

## Obrazy
Grafika skrzynki jest w `images/cases/whoops.webp`, zdjęcia skinów w `images/skins/*.webp`. Jeśli dodasz kolejne zdjęcia, zmienimy katalog i SQL. Upewnij się, że masz prawa do publicznego użycia obrazów.

## Ważne
ZIP nie może automatycznie skonfigurować Twojego konta Supabase ani opublikować się na Vercel. Wymagane są kroki powyżej. Przed szerszą premierą zalecane są dodatkowe testy i ochrona przed masowymi wywołaniami funkcji.
