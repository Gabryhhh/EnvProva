# AWS CloudFormation Environment Creator

Questo progetto Python consente di creare ambienti Cloud9 utilizzando AWS CloudFormation. Il programma chiede all'utente di inserire i parametri necessari e può eseguire ripetutamente il comando per creare nuovi ambienti, utilizzando il profilo AWS specificato dall'utente. È possibile creare più ambienti contemporaneamente, verificare lo stato degli stack creati, ottenere l'URL `ConsoleSignInLink`, ed eliminare specifici stack o tutti gli stack creati.

## Prerequisiti

- Python 3.x
- AWS CLI configurato
- Credenziali AWS configurate con profili appropriati

## Installazione

1. Clona questo repository sul tuo computer:
   ```bash
   git clone https://github.com/tuo-utente/aws-cloudformation-environment-creator.git
   cd aws-cloudformation-environment-creator
   ```

2. Installa la libreria `boto3` se non è già installata:
   ```bash
   pip install boto3
   ```

## File richiesti

- `template.yml`: Template CloudFormation che definisce le risorse da creare.

## Utilizzo

1. Esegui il programma:
   ```bash
   python3 program.py
   ```

2. Inserisci il nome del profilo AWS quando richiesto:
   ```text
   Inserisci il nome del profilo AWS da usare: sandbox
   ```

3. Segui le istruzioni per creare nuovi ambienti, eliminare specifici stack, verificare lo stato degli stack o uscire dal programma.

### Creare nuovi ambienti

Quando scegli l'opzione di creare nuovi ambienti, inserisci i nomi degli utenti IAM separati da virgola:
   ```text
   Vuoi creare nuovi ambienti, eliminare gli stack creati, o verificare lo status? (crea/elimina/verifica/esci): crea
   Inserisci i nomi degli utenti IAM separati da virgola: user1,user2,user3
   ```

Il programma creerà gli stack CloudFormation per ciascun utente specificato.

### Eliminare gli stack creati

Quando scegli l'opzione di eliminare gli stack, verranno mostrati gli stack disponibili per l'eliminazione. Puoi inserire i numeri degli stack da eliminare separati da virgola, o scegliere di eliminare tutti gli stack:
   ```text
   Vuoi creare nuovi ambienti, eliminare gli stack creati, o verificare lo status? (crea/elimina/verifica/esci): elimina
   Stack disponibili per l'eliminazione:
   1. user1-cloud9-stack
   2. user2-cloud9-stack
   3. user3-cloud9-stack
   Inserisci i numeri degli stack da eliminare separati da virgola, o 'tutti' per eliminarli tutti: 1,3
   ```

### Verificare lo stato degli stack

Quando scegli l'opzione di verificare lo stato, verranno mostrati gli stack disponibili per la verifica. Puoi inserire i numeri degli stack da verificare separati da virgola, o scegliere di verificarli tutti:
   ```text
   Vuoi creare nuovi ambienti, eliminare gli stack creati, o verificare lo status? (crea/elimina/verifica/esci): verifica
   Stack disponibili per la verifica dello status:
   1. user2-cloud9-stack
   Inserisci i numeri degli stack da verificare separati da virgola, o 'tutti' per verificarli tutti: tutti
   Status of user2-cloud9-stack: CREATE_COMPLETE
   ConsoleSignInLink: https://123456789012.signin.aws.amazon.com/console/
   ```

### Esempio di esecuzione

```text
$ python3 program.py
Inserisci il nome del profilo AWS da usare: sandbox
Vuoi creare nuovi ambienti, eliminare gli stack creati, o verificare lo status? (crea/elimina/verifica/esci): crea
Inserisci i nomi degli utenti IAM separati da virgola: davide,maria
Stack creation initiated successfully: arn:aws:cloudformation:eu-south-1:123456789012:stack/davide-cloud9-stack/abcdef1234567890
Stack creation initiated successfully: arn:aws:cloudformation:eu-south-1:123456789012:stack/maria-cloud9-stack/abcdef1234567891
Vuoi creare nuovi ambienti, eliminare gli stack creati, o verificare lo status? (crea/elimina/verifica/esci): verifica
Stack disponibili per la verifica dello status:
1. davide-cloud9-stack
2. maria-cloud9-stack
Inserisci i numeri degli stack da verificare separati da virgola, o 'tutti' per verificarli tutti: tutti
Status of davide-cloud9-stack: CREATE_COMPLETE
ConsoleSignInLink: https://123456789012.signin.aws.amazon.com/console/
Status of maria-cloud9-stack: CREATE_COMPLETE
ConsoleSignInLink: https://123456789012.signin.aws.amazon.com/console/
```

## Note

- Assicurati che il file `template.yml` sia nella stessa directory del programma Python.
- Puoi modificare il file `template.yml` per adattarlo alle tue esigenze specifiche.
- I parametri `InstanceType`, `AutomaticStopTime` e `UserPassword` sono attualmente fissati a valori specifici per semplificare l'esecuzione del programma. Puoi modificarli nel codice se necessario.