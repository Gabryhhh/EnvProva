import json
import os
import boto3
import threading

STACKS_FILE = 'created_stacks.json'

def get_parameters(user_name):
    parameters = [
        {"ParameterKey": "UserName", "ParameterValue": user_name},
        {"ParameterKey": "InstanceType", "ParameterValue": "t3.micro"},
        {"ParameterKey": "AutomaticStopTime", "ParameterValue": "60"},
        {"ParameterKey": "UserPassword", "ParameterValue": "Workshop1!"},
        {"ParameterKey": "RepositoryName", "ParameterValue": user_name},
    ]
    return parameters

def get_prerequirements_parameters():
    parameters = [
        {"ParameterKey": "VpcCidr", "ParameterValue": "10.0.0.0/16"},
        {"ParameterKey": "PublicSubnet1Cidr", "ParameterValue": "10.0.1.0/24"},
        {"ParameterKey": "PublicSubnet2Cidr", "ParameterValue": "10.0.2.0/24"},
        {"ParameterKey": "RepositoryName", "ParameterValue": "Workshop"}
    ]
    return parameters

def write_parameters_to_file(parameters, file_name):
    with open(file_name, 'w') as parameters_file:
        json.dump(parameters, parameters_file)

def load_created_stacks():
    if os.path.exists(STACKS_FILE):
        with open(STACKS_FILE, 'r') as file:
            return json.load(file)
    return []

def save_created_stack(stack_name):
    stacks = load_created_stacks()
    stacks.append(stack_name)
    with open(STACKS_FILE, 'w') as file:
        json.dump(stacks, file)

def create_cloudformation_client():
    session = boto3.Session()
    return session.client('cloudformation', region_name='eu-south-1')

def run_cloudformation_command(stack_name, parameters_file, template_file):
    client = create_cloudformation_client()
    
    with open(template_file, 'r') as file:
        template_body = file.read()
    
    with open(parameters_file, 'r') as file:
        parameters = json.load(file)
    
    try:
        response = client.create_stack(
            StackName=stack_name,
            TemplateBody=template_body,
            Parameters=parameters,
            Capabilities=['CAPABILITY_NAMED_IAM']
        )
        print(f"Stack creation initiated successfully: {response}")
        save_created_stack(stack_name)
    except Exception as e:
        print(f"Error initiating stack creation: {e}")

def delete_stacks(stacks_to_delete):
    client = create_cloudformation_client()
    stacks = load_created_stacks()
    for stack_name in stacks_to_delete:
        if stack_name in stacks:
            try:
                response = client.delete_stack(
                    StackName=stack_name
                )
                print(f"Stack deletion initiated successfully for {stack_name}")
                parameters_file = f'parameters_{stack_name.split("-")[0]}.json'
                if os.path.exists(parameters_file):
                    os.remove(parameters_file)
            except Exception as e:
                print(f"Error initiating stack deletion for {stack_name}: {e}")
            stacks.remove(stack_name)
    
    with open(STACKS_FILE, 'w') as file:
        json.dump(stacks, file)

def check_stack_status(stack_name):
    client = create_cloudformation_client()
    
    try:
        response = client.describe_stacks(StackName=stack_name)
        stack = response['Stacks'][0]
        stack_status = stack['StackStatus']
        print(f"Status of {stack_name}: {stack_status}")
        if stack_status == 'CREATE_COMPLETE':
            outputs = stack.get('Outputs', [])
            for output in outputs:
                if output['OutputKey'] == 'ConsoleSignInLink':
                    print(f"ConsoleSignInLink: {output['OutputValue']}")
    except Exception as e:
        print(f"Error describing stack: {e}")

def update_stack(stack_name, parameters_file, template_file):
    client = create_cloudformation_client()
    
    with open(template_file, 'r') as file:
        template_body = file.read()
    
    with open(parameters_file, 'r') as file:
        parameters = json.load(file)
    
    try:
        response = client.update_stack(
            StackName=stack_name,
            TemplateBody=template_body,
            Parameters=parameters,
            Capabilities=['CAPABILITY_NAMED_IAM']
        )
        print(f"Stack update initiated successfully for {stack_name}: {response}")
    except Exception as e:
        print(f"Error initiating stack update for {stack_name}: {e}")

def create_stack_for_user(user_name):
    parameters = get_parameters(user_name)
    parameters_file = f'parameters_{user_name}.json'
    write_parameters_to_file(parameters, parameters_file)
    stack_name = user_name + "-cloud9-stack"
    run_cloudformation_command(stack_name, parameters_file, 'template.yml')

def create_prerequirements_stack():
    parameters = get_prerequirements_parameters()
    parameters_file = 'parameters_prerequirements.json'
    write_parameters_to_file(parameters, parameters_file)
    stack_name = "prerequirements-stack"
    run_cloudformation_command(stack_name, parameters_file, 'prerequirements.yml')

def main():
    while True:
        action = input("Vuoi creare nuovi ambienti, creare i pre-requisiti, eliminare gli stack creati, verificare lo status, o aggiornare gli stack? (crea/prerequisiti/elimina/verifica/aggiorna/esci): ").strip().lower()
        if action == 'crea':
            usernames_input = input("Inserisci i nomi degli utenti IAM separati da virgola: ").strip()
            usernames = [name.strip() for name in usernames_input.split(',')]
            threads = []
            for user_name in usernames:
                thread = threading.Thread(target=create_stack_for_user, args=(user_name,))
                thread.start()
                threads.append(thread)

            for thread in threads:
                thread.join()

        elif action == 'prerequisiti':
            create_prerequirements_stack()

        elif action == 'elimina':
            stacks = load_created_stacks()
            if not stacks:
                print("Non ci sono stack da eliminare.")
                continue

            print("Stack disponibili per l'eliminazione:")
            for i, stack in enumerate(stacks, 1):
                print(f"{i}. {stack}")
            
            choices = input("Inserisci i numeri degli stack da eliminare separati da virgola, o 'tutti' per eliminarli tutti: ").strip().lower()
            if choices == 'tutti':
                delete_stacks(stacks)
            else:
                try:
                    indices = [int(x.strip()) - 1 for x in choices.split(',')]
                    stacks_to_delete = [stacks[i] for i in indices]
                    delete_stacks(stacks_to_delete)
                except (ValueError, IndexError):
                    print("Scelta non valida. Riprova.")

        elif action == 'verifica':
            stacks = load_created_stacks()
            if not stacks:
                print("Non ci sono stack da verificare.")
                continue

            print("Stack disponibili per la verifica dello status:")
            for i, stack in enumerate(stacks, 1):
                print(f"{i}. {stack}")
            
            choices = input("Inserisci i numeri degli stack da verificare separati da virgola, o 'tutti' per verificarli tutti: ").strip().lower()
            if choices == 'tutti':
                for stack in stacks:
                    check_stack_status(stack)
            else:
                try:
                    indices = [int(x.strip()) - 1 for x in choices.split(',')]
                    stacks_to_check = [stacks[i] for i in indices]
                    for stack in stacks_to_check:
                        check_stack_status(stack)
                except (ValueError, IndexError):
                    print("Scelta non valida. Riprova.")

        elif action == 'aggiorna':
            stacks = load_created_stacks()
            if not stacks:
                print("Non ci sono stack da aggiornare.")
                continue

            print("Stack disponibili per l'aggiornamento:")
            for i, stack in enumerate(stacks, 1):
                print(f"{i}. {stack}")

            choices = input("Inserisci i numeri degli stack da aggiornare separati da virgola, o 'tutti' per aggiornarli tutti: ").strip().lower()
            if choices == 'tutti':
                for stack in stacks:
                    if stack == "prerequirements-stack":
                        parameters_file = 'parameters_prerequirements.json'
                        template_file = 'prerequirements.yml'
                    else:
                        user_name = stack.split("-")[0]
                        parameters_file = f'parameters_{user_name}.json'
                        template_file = 'template.yml'
                    update_stack(stack, parameters_file, template_file)
            else:
                try:
                    indices = [int(x.strip()) - 1 for x in choices.split(',')]
                    stacks_to_update = [stacks[i] for i in indices]
                    for stack in stacks_to_update:
                        if stack == "prerequirements-stack":
                            parameters_file = 'parameters_prerequirements.json'
                            template_file = 'prerequirements.yml'
                        else:
                            user_name = stack.split("-")[0]
                            parameters_file = f'parameters_{user_name}.json'
                            template_file = 'template.yml'
                        update_stack(stack, parameters_file, template_file)
                except (ValueError, IndexError):
                    print("Scelta non valida. Riprova.")

        elif action == 'esci':
            break
        else:
            print("Azione non valida. Per favore, inserisci 'crea', 'prerequisiti', 'elimina', 'verifica', 'aggiorna' o 'esci'.")

if __name__ == "__main__":
    main()
