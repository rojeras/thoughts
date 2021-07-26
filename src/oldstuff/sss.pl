:- use_module(library(http/json)).

sss :-
json_write(user_output,
  json(
    serviceConsumers=[json(id='SE2321000016-8K5F')],
    serviceContracts=[json(id='urn:riv:infrastructure:eservicesupply:forminteraction:CreateFormResponder:2'),
                      json(id='urn:riv:infrastructure:eservicesupply:forminteraction:GetFormQuestionPageResponder:2'),
                      json(id='urn:riv:infrastructure:eservicesupply:forminteraction:GetFormResponder:2'),
                      json(id='urn:riv:infrastructure:eservicesupply:forminteraction:GetFormTemplatesResponder:2'),
                      json(id='urn:riv:infrastructure:eservicesupply:forminteraction:GetFormsResponder:2'),
                      json(id='urn:riv:infrastructure:eservicesupply:forminteraction:SaveFormPageResponder:2'),
                      json(id='urn:riv:infrastructure:eservicesupply:forminteraction:SaveFormResponder:2'),json(id='urn:riv:infrastructure:supportservices:forminteraction:CancelFormResponder:1'),json(id='urn:riv:infrastructure:supportservices:forminteraction:CreateFormRequestResponder:1'),json(id='urn:riv:infrastructure:supportservices:forminteraction:CreateFormResponder:1'),json(id='urn:riv:infrastructure:supportservices:forminteraction:GetFormQuestionPageResponder:1'),json(id='urn:riv:infrastructure:supportservices:forminteraction:GetFormResponder:1'),json(id='urn:riv:infrastructure:supportservices:forminteraction:GetFormTemplatesResponder:1'),json(id='urn:riv:infrastructure:supportservices:forminteraction:GetFormsResponder:1'),
                      json(id='urn:riv:infrastructure:supportservices:forminteraction:SaveFormPageResponder:1'),
                      json(id='urn:riv:infrastructure:supportservices:forminteraction:SaveFormResponder:1')],
    logicalAddresses=[json(id='SE2321000016-8K5D')],
    serviceProducers=[json(id='SE2321000016-8K5D')],
    plattformChains=[json(id='NTJP-PROD')]
  )
).

sss2 :-
json_write(user_output,
  json([
    serviceConsumers=[json([id='SE2321000016-8K5F'])],
    serviceContracts=[
                      json([id='urn:riv:infrastructure:eservicesupply:forminteraction:CreateFormResponder:2']),
                      json([id='urn:riv:infrastructure:supportservices:forminteraction:SaveFormResponder:1'])
                      ]
       ])
).
