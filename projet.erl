-module(projet).
-export([setnth/3,action/5,interne/1,traite/2,looprecep/6,inithorloge/2,initproc/4,test/2,start/1]).


% Une fonction qui permet de changer la valeur du i éme element d'une liste par la valeur new
setnth(1, [_|Rest], New) -> [New|Rest];
setnth(I, [E|Rest], New) -> [E|setnth(I-1, Rest, New)].


% Fonction qui demande à un process d'envoyer un message à un autre 
% N c'est le nombre total des Processus | Numrecep c'est le numero du processus qui va recevoir le message 
% Nummsg c'est le numéro du message envoyé (Ce sont des paramétres qui vont étre utilisés dans l'affichage pour que ca soit clair).
action(N,SITE_ENVOI,SITE_RECEP,Numrecep,Nummsg)->
	SITE_ENVOI ! {send,SITE_RECEP,Numrecep,Nummsg,N}.


%Fonction qui demande à un process de simuler un evenement interne 
interne(SITE)->
	SITE ! eveninterne .
   

%Fonction qui traite les differents messages reçus sur les sites
traite(Numsite,Estamp)->
    receive 
        %Le Site recoit la manip qui lui indique qu'un evenement interne se produit
        eveninterne ->
                NouvEstamp=setnth(Numsite,Estamp,lists:nth(Numsite,Estamp)+1),     %équivaut à EVi[i]++
		io:format("SITE ~w a:~n	un evenement interne ~n",[Numsite]),
		io:format("* Estampille du site ~w:~n	avant: ~w =====>  aprés: ~w ~n",[Numsite,Estamp,NouvEstamp]),
                traite(Numsite,NouvEstamp);

        %Le Site recoit la manip qui lui demande d'envoyer un message à SITERECEP
	{send,SITERECEP,Numrecep,Nummsg,N} ->
		NouvEstamp=setnth(Numsite,Estamp,lists:nth(Numsite,Estamp)+1),          %équivaut à EVi[i]++
		io:format("SITE ~w envoie:~n	MSG Num ~w au SITE ~w avec l'estampille ~w ~n",[Numsite,Nummsg,Numrecep,NouvEstamp]),
      		io:format("* Estampille du site ~w:~n	avant: ~w =====> aprés: ~w ~n",[Numsite,Estamp,NouvEstamp]),
		%Aprés incrementation, on envoie l'estampille aussi au 
		%récépteur. Les autres parametres sont surtout pour l'affichage
                SITERECEP ! {NouvEstamp,Nummsg,Numsite,Numrecep,N} ,                
                traite(Numsite,NouvEstamp);	
	
         %Le site reçoit le message d'un autre site 	
  	 {EstampEmet,Nummsg,Numemet,Numrecep,N} ->
		%EstampIntermed représente l'estampille aprés avoir incrémenter EVi[i] mais pas encore modifier EVi[j]
     		EstampIntermed=setnth(Numrecep,Estamp,lists:nth(Numrecep,Estamp)+1), 
		io:format("SITE ~w recoit:~n	MSG Num ~w du SITE ~w qui a envoyé l'estampille ~w ~n",[Numrecep,Nummsg,Numemet,EstampEmet]),		
		looprecep(Numsite,N,Estamp,EstampEmet,EstampIntermed,Numrecep)
		
    end.


%Fonction qui permet de comparer EVi[j] et EVj[j] pour tout j != i 
%afin d'avoir la nouvelle estampille du site 
looprecep(Numsite,0,Estamp,_,NouvEstamp,Numrecep) ->
	io:format("* Estampille du site ~w:~n	avant: ~w =====> aprés: ~w ~n",[Numrecep,Estamp,NouvEstamp]),
	traite(Numsite,NouvEstamp);

looprecep(Numsite,Count,Estamp,EstampEmet,EstampIntermed,Numrecep) ->
     if
     Count/=Numrecep -> 
         %Comparaison entre EVi[j] et EVj[j]
       	 X=lists:nth(Count,EstampIntermed),
	 Y=lists:nth(Count,EstampEmet),
	 if
	 X<Y ->
   		NouvEstamp=setnth(Count,EstampIntermed,Y);		
         true ->
   		NouvEstamp=setnth(Count,EstampIntermed,X)
         end,
         looprecep(Numsite,Count-1,Estamp,EstampEmet,NouvEstamp,Numrecep);
     true ->
         looprecep(Numsite,Count-1,Estamp,EstampEmet,EstampIntermed,Numrecep)
      end.


%Fonction pour initialiser la liste qui représente l'estampille.
inithorloge(L,0)->
	L;

inithorloge(L,N)->
	Estamp=L ++ [0],
	inithorloge(Estamp,N-1).

%Fonction pour créer une liste de processus 
initproc(Proc,_,0,_)->
	Proc;


initproc(Proc,L,N,F)->                  %Le 4eme argument est ajouté pour permettre de stocker les processus avec des Numsite 
					%dans l'ordre croissant dans la liste de 1 à N et pas le contraire(de N à 1).	
					%Exemple:au lieu que le premier spawn de la liste appelle traite(N,L),ce sera plutot traite(1,L)
      	Process=Proc ++ [spawn(projet,traite,[F+1-N,L])],
	initproc(Process,L,N-1,F).


%Fonction pour tester
%Exemple de scénario pour N >=3 
test(N,Process)->
	%Remarque: Pour la fct action:
	%Si le 3éme argument référe au N éme élement de la liste de Process,le 4eme argument doit etre N aussi
	action(N,lists:nth(1, Process),lists:nth(2, Process),2,1),   %Le site 1 envoie message au site 2  
 	action(N,lists:nth(3, Process),lists:nth(1, Process),1,2),
 	action(N,lists:nth(2, Process),lists:nth(3, Process),3,3),
 	action(N,lists:nth(3, Process),lists:nth(1, Process),1,4), 
	action(N,lists:nth(1, Process),lists:nth(2, Process),2,5), 
 	interne(lists:nth(1, Process)),
 	interne(lists:nth(3, Process)).


start(N)->
	L=[],
	Proc=[],
 	Horloge=inithorloge(L,N),
 	Process=initproc(Proc,Horloge,N,N),
        test(N,Process).
 	



