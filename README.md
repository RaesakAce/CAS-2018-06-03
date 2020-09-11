#Monitoraggio Sensori in Smart Vehicles: Progetto MIPS A.A. 2017/2018
Il progetto consiste nello sviluppo di un algoritmo implementato in codice assembly MIPS di una unità di
monitoraggio che determini la correttezza dei sensori di una automobile. Al tempo t l’unità di monitoraggio
riceve da tre sensori un valore, che deve essere verificato al fine di determinare il corretto funzionamento del
sensore stesso. Inoltre dev’essere determinato il corretto funzionamento dei sensori nel complesso secondo le
seguenti politiche di aggregazione:
- P3(t) : Almeno uno dei tre sensori funziona correttamente al tempo t.
- P2(t) : Almeno due dei tre sensori funziona correttamente al tempo t.
- P1(t) : Tutti i sensori funzionano correttamente al tempo t.
Sia l’input fornito dai tre sensori che i sei output, che indicano il corretto funzionamento per ognuno dei tre
sensori e il corretto funzionamento del sistema secondo le varie politiche di aggregazione, sono file di testo
che devono trovarsi nella stessa cartella dell’eseguibile dell’assemblatore. Le operazioni dovranno eseguite
per ogni t con (t) totale uguale 100.
##Descrizione della soluzione adottata
L’unità di monitoraggio per prima cosa riceve i 100 input da ognuno dei 3 sensori e li carica su 3 diversi
buffer, il cui indirizzo viene caricato in tre diversi registri. Carica inoltre in altri 6 registri i buffer di uscita
dei 6 output. A quel punto inizia un ciclo che si ripete 100 volte, per il quale il registro $t0 agisce da
contatore, in cui 4 procedure diverse vengono chiamate, e per le quali i registri temporanei vengono salvati
nello stack, in modo che non siano modificati dalle prime 3 procedure, mentre le quarta procedura li utilizza,
perciò ha accesso ai valori da modificare. Le prime tre procedure sono rispettivamente la procedura che
restituisce la correttezza del sensore di pendenza, quella che restituisce la correttezza del sensore dello sterzo
e quella che restituisce la correttezza del sensore di distanza da ostacoli. Al ritorno il risultato di ognuna delle
procedure viene caricato in tre registri che vengono passati alla quarta procedura che si trova nel ciclo.
Questa procedura, pone nei buffer di uscita appropriati i risultati della valutazione dei sensori, inoltre valuta
il sistema secondo le 3 politiche di aggregazione e salva i risultati nei tre buffer appropriati. Questo viene
ripetuto fino a che $t0 non raggiunge il valore 100 nel ciclo principale, a quel punto i buffer di uscita
vengono utilizzati nel chiamare la procedura che li stampa nel file .txt che li pertiene. 

#Relazione completa:
https://github.com/RaesakAce/MIPS-smart-vehicles/blob/master/RelazioneAeMarcoCasaglia2017-2018.pdf

