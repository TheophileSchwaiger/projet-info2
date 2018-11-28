local
   % See project statement for API details.
   [Project] = {Link ['Project2018.ozf']}
   Time = {Link ['x-oz://boot/Time']}.1.getReferenceTime

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   % Translate a note to the extended notation.
   fun {NoteToExtended Note}
      case Note
      of Name#Octave then
         note(name:Name octave:Octave sharp:true duration:1.0 instrument:none)
      [] Atom then
         case {AtomToString Atom}
         of [_] then
            note(name:Atom octave:4 sharp:false duration:1.0 instrument:none)
         [] [N O] then
            note(name:{StringToAtom [N]}
                 octave:{StringToInt [O]}
                 sharp:false
                 duration:1.0
                 instrument: none)
         end
      end
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   fun {PartitionToTimedList Partition}
      % TODO
      nil
   end
   

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   fun {Mix P2T Music}
      % TODO
      {Project.readFile 'wave/animaux/cow.wav'}
   end




%Modifie la duree    
   fun {Duration Time Partition}
      local
	 A = {NewCell 0}
	 D
      in
	 local
	    %Calcule la duree de la partition
	    fun {HowLong Partition}
	       case Partition of H|T then
		  case H of silence(duration:D) then
		     A := A+D
		     {Howlong T}
		  [] note(name:N octave:O sharp:$ duration:D instrument:I) then
		     A := A+D
		     {HowLong T}
		  [] Head|Tail then
		     case Head of silence(duration:D) then
			A:= A+D
			{HowLong T}
		     [] Head of note(name:N octave:O sharp:$ duration:D instrument:I) then
			A:=A+D
			{HowLong T}
		     end
		  end
		  A
	       end
	    end
	 in
	    D = {HowLong Partition}
	    if D\= 0 then
	       {Stretch Time/D Partition}
	    else
	       0.0
	    end
	 end
      end
   end
%etire la partion d'un facteur Facteur
   fun {Stretch Facteur Partition}
      local
	 S
      in
	 case Partition of H|T then
	    case H of silence(duration:D) then
	       silence(duration:D*Facteur)|{Stretch Facteur T}%on redefinit la longeur duration
	    [] note(name:N octave:O sharp:$ duration:D instrument:I) then
	       note(name:N octave:O sharp:$ duration:D*Facteur instrument:I)|{Stretch Facteur T}
	    [] Head|Tail then
	       case Head of silence(duration:D) then
		  silence(duration:D*Facteur)|{Stretch Facteur Tail}
	       [] Head of note(name:N octave:O sharp:$ duration:D instrument:I) then
		  note(name:N octave:O sharp:$ duration:D*K instrument:I)|{Stretch Facteur Tail}
	       end
	    end
	 end
      end
   end
%repete une note ou un accord amount fois
   fun{Drone Note Amount}
      for I in 0..Amount-1 do
	 Note:={Append Note Note}
      end
      Note
   end


  
	 fun{Transpose N2 Partition}%augmente chaque note de la partion de N2 demi-tons
	    local
	       fun{GetNote List Elem Acc}%renvoie la position de lelement dans la liste a partir de acc
		  case List H|T then
		     if H\=Elem then
			{GetNumber T Elem Acc+1}
		     else
			Acc
		     end
		  else
		     nil
		  end
	       end
	       fun{GetOctave List N3 Elem2}%permet de calculer le nombre d octaves montees ou descendues en fonction des N3 demi-tons
		  local
		     I = {NewCell 0}
		  in
		     if N3>0 then
		     for (while N3>{List.length List}+1-Elem2+12*I) do %on parcourt les octaves jusqua ce que on depasse les nombre de demi-tons montes
		     I:=I+1
		     end
		     else
			for (while N3<=-Elem2-12*I) do %on parcourt dans lautre sens si le nombre de demi-tons est negatifs
			   I:=I-1
			end
		     end
		     I
		  end
	       L = [C C# D D# E F F# G G# A A# B]%notes dans une octave
	       in
		  case Partition of H|T then
		     case H of silence(duration:D) then
			silence(duration:D)|{Transpose N2 T} %si cest un silence rien ne change
		     [] note(name:Name octave:Octave sharp:$ duration:D instrument:I) then
			{NoteToExtended {List.nth L {GetNote L Name 1}+N2}+Octave+{GetOctave L N2 {GetNote L Name 1}}}|{Transpose N2 T}%renvoie la version etendue de la note simplifiee donnee par la lettre dans la liste et loctave
		     [] of Head|Tail then
			case Head of silence(duration:D) then
			   silence(duration:D)|{Transpose N2 Tail}
			[] of note(name:Name octave:Octave sharp:$ duration:D instrument:I) then
			   {NoteToExtended {List.nth L {GetNote L Name 1}+N2}+Octave+{GetOctave L N2 {GetNote L Name 1}}}|{Transpose N2 Tail}
			end
		     end
		  end
	       end
	    end
	 end
	 
	    
			   
			
		     
   
	
	 
	       
	       
	 
	
   
      
      
      
	    
	    
	    
	    
	  

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   Music = {Project.load 'joy.dj.oz'}
   Start

   % Uncomment next line to insert your tests.
   % \insert 'tests.oz'
   % !!! Remove this before submitting.
in
   Start = {Time}

   % Uncomment next line to run your tests.
   % {Test Mix PartitionToTimedList}

   % Add variables to this list to avoid "local variable used only once"
   % warnings.
   {ForAll [NoteToExtended Music] Wait}
   
   % Calls your code, prints the result and outputs the result to `out.wav`.
   % You don't need to modify this.
   {Browse {Project.run Mix PartitionToTimedList Music 'out.wav'}}
   
   % Shows the total time to run your code.
   {Browse {IntToFloat {Time}-Start} / 1000.0}
end