;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-advanced-reader.ss" "lang")((modname finalproject) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #t #t none #f () #f)))
(require "adventure-define-struct.rkt")
(require "macros.rkt")
(require "utilities.rkt")

;;;
;;; OBJECT
;;; Base type for all in-game objects
;;;

(define-struct object
  ;; adjectives: (listof string)
  ;; List of adjectives to be printed in the description of this object
  (adjectives)
  
  #:methods
  ;; noun: object -> string
  ;; Returns the noun to use to describe this object.
  (define (noun o)
    (type-name-string o))

  ;; description-word-list: object -> (listof string)
  ;; The description of the object as a list of individual
  ;; words, e.g. '("a" "red" "door").
  (define (description-word-list o)
    (add-a-or-an (append (object-adjectives o)
                         (list (noun o)))))
  ;; description: object -> string
  ;; Generates a description of the object as a noun phrase, e.g. "a red door".
  (define (description o)
    (words->string (description-word-list o)))
  
  ;; print-description: object -> void
  ;; EFFECT: Prints the description of the object.
  (define (print-description o)
    (begin (printf (description o))
           (newline)
           (void))))

;;;
;;; CONTAINER
;;; Base type for all game objects that can hold things
;;;

(define-struct (container object)
  ;; contents: (listof thing)
  ;; List of things presently in this container
  (contents)
  
  #:methods
  ;; container-accessible-contents: container -> (listof thing)
  ;; Returns the objects from the container that would be accessible to the player.
  ;; By default, this is all the objects.  But if you want to implement locked boxes,
  ;; rooms without light, etc., you can redefine this to withhold the contents under
  ;; whatever conditions you like.
  (define (container-accessible-contents c)
    (container-contents c))
  
  ;; prepare-to-remove!: container thing -> void
  ;; Called by move when preparing to move thing out of
  ;; this container.  Normally, this does nothing, but
  ;; if you want to prevent the object from being moved,
  ;; you can throw an exception here.
  (define (prepare-to-remove! container thing)
    (void))
  
  ;; prepare-to-add!: container thing -> void
  ;; Called by move when preparing to move thing into
  ;; this container.  Normally, this does nothing, but
  ;; if you want to prevent the object from being moved,
  ;; you can throw an exception here.
  (define (prepare-to-add! container thing)
    (void))
  
  ;; remove!: container thing -> void
  ;; EFFECT: removes the thing from the container
  (define (remove! container thing)
    (set-container-contents! container
                             (remove thing
                                     (container-contents container))))
  
  ;; add!: container thing -> void
  ;; EFFECT: adds the thing to the container.  Does not update the thing's location.
  (define (add! container thing)
    (set-container-contents! container
                             (cons thing
                                   (container-contents container))))

  ;; describe-contents: container -> void
  ;; EFFECT: prints the contents of the container
  (define (describe-contents container)
    (begin (local [(define other-stuff (remove me (container-accessible-contents container)))]
             (if (empty? other-stuff)
                 (printf "There's nothing here.~%")
                 (begin (printf "You see:~%")
                        (for-each print-description other-stuff))))
           (void))))

;; move!: thing container -> void
;; Moves thing from its previous location to container.
;; EFFECT: updates location field of thing and contents
;; fields of both the new and old containers.
(define (move! thing new-container)
  (begin
    (prepare-to-remove! (thing-location thing)
                        thing)
    (prepare-to-add! new-container thing)
    (prepare-to-move! thing new-container)
    (remove! (thing-location thing)
             thing)
    (add! new-container thing)
    (set-thing-location! thing new-container)))

;; destroy!: thing -> void
;; EFFECT: removes thing from the game completely.
(define (destroy! thing)
  ; We just remove it from its current location
  ; without adding it anyplace else.
  (remove! (thing-location thing)
           thing))

;;;
;;; ROOM
;;; Base type for rooms and outdoor areas
;;;

(define-struct (room container)
  ())

;; new-room: string -> room
;; Makes a new room with the specified adjectives
(define (new-room adjectives)
  (make-room (string->words adjectives)
             '()))

;;;
;;; THING
;;; Base type for all physical objects that can be inside other objects such as rooms
;;;

(define-struct (thing container)
  ;; location: container
  ;; What room or other container this thing is presently located in.
  (location)
  
  #:methods
  (define (examine thing)
    (print-description thing))

  ;; prepare-to-move!: thing container -> void
  ;; Called by move when preparing to move thing into
  ;; container.  Normally, this does nothing, but
  ;; if you want to prevent the object from being moved,
  ;; you can throw an exception here.
  (define (prepare-to-move! container thing)
    (void)))

;; initialize-thing!: thing -> void
;; EFFECT: adds thing to its initial location
(define (initialize-thing! thing)
  (add! (thing-location thing)
        thing))

;; new-thing: string container -> thing
;; Makes a new thing with the specified adjectives, in the specified location,
;; and initializes it.
(define (new-thing adjectives location)
  (local [(define thing (make-thing (string->words adjectives)
                                    '() location))]
    (begin (initialize-thing! thing)
           thing)))

;;;
;;; DOOR
;;; A portal from one room to another
;;; To join two rooms, you need two door objects, one in each room
;;;

(define-struct (door thing)
  ;; destination: container
  ;; The place this door leads to
  (destination)
  
  #:methods
  ;; go: door -> void
  ;; EFFECT: Moves the player to the door's location and (look)s around.
  (define (go door)
    (begin (move! me (door-destination door))
           (look))))

;; join: room string room string
;; EFFECT: makes a pair of doors with the specified adjectives
;; connecting the specified rooms.
(define (join! room1 adjectives1 room2 adjectives2)
  (local [(define r1->r2 (make-door (string->words adjectives1)
                                    '() room1 room2))
          (define r2->r1 (make-door (string->words adjectives2)
                                    '() room2 room1))]
    (begin (initialize-thing! r1->r2)
           (initialize-thing! r2->r1)
           (void))))

;;;
;;; PERSON
;;; A character in the game.  The player character is a person.
;;;

(define-struct (person thing)
  ())

;; initialize-person: person -> void
;; EFFECT: do whatever initializations are necessary for persons.
(define (initialize-person! p)
  (initialize-thing! p))

;; new-person: string container -> person
;; Makes a new person object and initializes it.
(define (new-person adjectives location)
  (local [(define person
            (make-person (string->words adjectives)
                         '()
                         location))]
    (begin (initialize-person! person)
           person)))

;; This is the global variable that holds the person object representing
;; the player.  This gets reset by (start-game)
(define me empty)

;;;
;;; PROP
;;; A thing in the game that doesn't serve any purpose other than to be there.
;;;

(define-struct (prop thing)
  (;; noun-to-print: string
   ;; The user can set the noun to print in the description so it doesn't just say "prop"
   noun-to-print
   ;; examine-text: string
   ;; Text to print if the player examines this object
   examine-text
   )
  
  #:methods
  (define (noun prop)
    (prop-noun-to-print prop))

  (define (examine prop)
    (display-line (prop-examine-text prop))))

;; new-prop: string container -> prop
;; Makes a new prop with the specified description.
(define (new-prop description examine-text location)
  (local [(define words (string->words description))
          (define noun (last words))
          (define adjectives (drop-right words 1))
          (define prop (make-prop adjectives '() location noun examine-text))]
    (begin (initialize-thing! prop)
           prop)))

;;;
;;; ADD YOUR TYPES HERE!
;;;


(define-struct (chest thing)
(open?)
  #:methods
  (define (open c)
    (set-chest-open?! c #true))
  (define (close c)
    (set-chest-open?! c #false))
  (define (chest-accessible-contents c)
    (if (chest-open? c)
        (container-contents c)
        '())))



  

(define-struct (book chest)
  ()
  #:methods
 (define (read b)
    (if (chest-open? b)
        (display-line "When shall we three meet again?")
        (display-line "Macbeth"))
  ))



(define (new-book adjectives location)
  (local [(define the-book (make-book (string->words adjectives)
                                        '() location
                                        false))]
    (begin (initialize-thing! the-book)
           the-book)))


(define-struct (lockbox chest)
  (locked? password)
  #:methods

  (define (open l)
    (if (lockbox-locked? l)
        (display-line "The lockbox is locked.")
        (begin
        (set-chest-open?! l #true)
        (describe-contents l))))

    (define (unlock l pass)
      (if (equal? (lockbox-password l) pass)
          (set-lockbox-locked?! l #false)
          (display-line "Wrong password"))))
  
 (define (new-lockbox adjectives password location)
  (local [(define the-lockbox (make-lockbox (string->words adjectives)
                                        '() location
                                        false
                                        true
                                        password))]
    (begin (initialize-thing! the-lockbox)
           the-lockbox)))

 (define-struct (poster thing)
  ()
  #:methods
  (define (view p)
    (display-line "The password goes beyond the cover. And there is a picture of a cat. Take the book TO GO...it will come in HANDY later")))

(define (new-poster adjectives location)
  (local [(define the-poster (make-poster (string->words adjectives)
                                    '() location))]
    (begin (initialize-thing! the-poster)
           the-poster)))

  
(define-struct (kitchen-appliance chest)
  (locked?)

  #:methods
  
  (define (unlock a)
      (if (empty? (my-inventory))
          (display-line "It's locked!")
          (set-kitchen-appliance-locked?! a #false)))
  (define (open a)
    (if (kitchen-appliance-locked? a)
          (display-line "The appliance is locked. Unlock it.")
          (begin
          (set-chest-open?! a #true)
          (describe-contents a)
          ))))

(define-struct (fridge kitchen-appliance)
()
  )

(define (new-fridge adjectives location)
  (local [(define the-fridge (make-fridge (string->words adjectives)
                                        '() location
                                        false
                                        true))]
    (begin (initialize-thing! the-fridge)
           the-fridge)))

(define-struct (pantry kitchen-appliance)
  ())

(define (new-pantry adjectives location)
  (local [(define the-pantry (make-pantry (string->words adjectives)
                                        '() location
                                        false
                                        true))]
    (begin (initialize-thing! the-pantry)
           the-pantry)))

(define-struct (freezer kitchen-appliance)
  ())

(define (new-freezer adjectives location)
  (local [(define the-freezer (make-freezer (string->words adjectives)
                                        '() location
                                        false
                                        true))]
    (begin (initialize-thing! the-freezer)
           the-freezer)))

 (define-struct (fruit-basket kitchen-appliance)
  ())

(define (new-fruit-basket adjectives location)
  (local [(define the-fruit-basket (make-fruit-basket (string->words adjectives)
                                        '() location
                                        false
                                        true))]
    (begin (initialize-thing! the-fruit-basket)
           the-fruit-basket)))

(define-struct (human-body-storage kitchen-appliance)
  ())
(define (new-human-body-storage adjectives location)
  (local [(define the-human-body-storage (make-human-body-storage (string->words adjectives)
                                        '() location
                                        false
                                        true))]
    (begin (initialize-thing! the-human-body-storage)
           the-human-body-storage)))



(define-struct (grill kitchen-appliance)
  (clean?)
  #:methods
  (define (clean g)
    (set-grill-clean?! g true))

  (define (cook g f)
    (if (grill-clean? g)
        (begin
          (set-object-adjectives! f (cons "cooked" (object-adjectives f)))
          (display-line "cooked!"))
          
        (display-line "the grill needs to be cleaned"))))

(define (new-grill adjectives location)
  (local [(define the-grill (make-grill (string->words adjectives)
                                        '() location
                                        false
                                        false
                                        false))]
    (begin (initialize-thing! the-grill)
           the-grill)))

(define-struct (toaster-oven kitchen-appliance)
  (plugged-in?)
  #:methods
  (define (plug-in t)
    (set-toaster-oven-plugged-in?! t true))

  (define (toast t f)
    (if (toaster-oven-plugged-in? t)
        (begin
          (set-object-adjectives! f (cons "cooked" (object-adjectives f)))
          (display-line "cooked!"))
        (display-line "the toaster oven needs to be plugged in"))))

(define (new-toaster-oven adjectives location)
  (local [(define the-toaster-oven (make-toaster-oven (string->words adjectives)
                                        '() location
                                        false
                                        false
                                        false))]
    (begin (initialize-thing! the-toaster-oven)
           the-toaster-oven)))


(define-struct (microwave kitchen-appliance)
  (smacked?)
  #:methods
  (define (smack m)
    (set-microwave-smacked?! m #true))
  (define (heat m f)
    (if (microwave-smacked? m)
        (begin
          (set-object-adjectives! f (cons "cooked" (object-adjectives f)))
          (display-line "cooked!"))
        (display-line "the microwave is broken. Give it a nice big smack to fix it!"))))

  (define (new-microwave adjectives location)
  (local [(define the-microwave (make-microwave (string->words adjectives)
                                        '() location
                                        false
                                        false
                                        false))]
    (begin (initialize-thing! the-microwave)
           the-microwave)))

  
(define-struct (blender kitchen-appliance)
  (blade-installed?)
  #:methods
  (define (install-blade b)
    (set-blender-blade-installed?! b #true))
   (define (blend b f)
    (if (blender-blade-installed? b)
        (begin
          (set-object-adjectives! f (cons "blended" (object-adjectives f)))
          (display-line "blended"))
        (display-line "the fruit basket is just straw right now! you need to weave it."))))

 (define (new-blender adjectives location)
  (local [(define the-blender (make-blender (string->words adjectives)
                                        '() location
                                        false
                                        false
                                        false))]
    (begin (initialize-thing! the-blender)
           the-blender)))

 (define-struct (human-body-grinder kitchen-appliance)
   (body-installed?)
   #:methods
   (define (insert-human-body h)
     (set-human-body-grinder-body-installed?! h #true))
   (define (grind h hb)
     (if (human-body-grinder-body-installed? h)
         (begin
          (set-object-adjectives! hb (cons "grinded" (object-adjectives hb)))
          (display-line "grinded"))
        (display-line "There is no human body in the grinderer"))))

 (define (new-human-body-grinder adjectives location)
  (local [(define the-human-body-grinder (make-human-body-grinder (string->words adjectives)
                                        '() location
                                        false
                                        false
                                        false))]
    (begin (initialize-thing! the-human-body-grinder)
           the-human-body-grinder)))
 
(define (drink thing)
  (if (is-a? thing "blended")
      (begin
        (destroy! thing)
        (display-line "Delicious"))
      (display-line "You can't drink a solid.")))

(define (spread thing)
  (if (is-a? thing "grinded")
      (begin
        (destroy! thing)
        (display-line "the human has been spread on the kitcken floor"))
      (display-line "you're not strong enough to spread out a full human body")))

(define-struct (clown thing)
  ()
  #:methods
  (define (approach c)
    (display-line "He is juggling. Tap his shoulder?"))
  
  (define (tap c)
    (begin (display-line "The clown pulls out a knife and stabs you in the jugular. He screams, \"YOU WILL NEVER ESCAPE!\"")
           (start-game)
           (look))))

 (define (new-clown adjectives location)
  (local [(define the-clown (make-clown (string->words adjectives)
                                    '() location))]
    (begin (initialize-thing! the-clown)
           the-clown)))

  (define-struct (chef thing)
    ()
    #:methods
  (define (approach c)
    (display-line "He looks busy. Tap him?"))
  
  (define (tap c)
    (begin (display-line "\n The chef turns around slowly. \n He grabs your arm and drags you accross the floor. \n You hear a loud whirring sound. The blender. \n You scream for help but nobody hears. \n The chef chuckles as he forces your hand into the blender. \n \"Goodbye,\" he whispers as he drives a turkey baster through your skull...")
           (start-game)
           (look))))
    
  (define (new-chef adjectives location)
  (local [(define the-chef (make-chef (string->words adjectives)
                                    '() location))]
    (begin (initialize-thing! the-chef)
           the-chef)))

(define-struct (button thing)
  (pressed?)
  #:methods
  (define (approach b)
    (display-line "Whatever you do, don't press the button."))
  (define (press b)
    (if (have? (the book))
    (display-line "File #<path:Adventure/adventure.rkt> successfully deleted \n \n \n \n \n \n \n \n \n \n Kidding! YOU WIN!")
    (display-line "BOOK it back to the other room and get some more knowledge!"))))

(define (new-button adjectives location)
  (local [(define the-button (make-button (string->words adjectives)
                                    '() location
                                    false))]
    (begin (initialize-thing! the-button)
           the-button)))

(define (eat thing)
  (if (is-a? thing "cooked")
      (begin
        (destroy! thing)
        (display-line "Yum, Yum"))
      (display-line "I only eat cooked food. I don't want salmonella.")))
 


;;;
;;; USER COMMANDS
;;;

(define (look)
  (begin (printf "You are in ~A.~%"
                 (description (here)))
         (describe-contents (here))
         (void)))

(define-user-command (look) "Prints what you can see in the room")

(define (inventory)
  (if (empty? (my-inventory))
      (printf "You don't have anything.~%")
      (begin (printf "You have:~%")
             (for-each print-description (my-inventory)))))

(define-user-command (inventory)
  "Prints the things you are carrying with you.")

(define-user-command (examine thing)
  "Takes a closer look at the thing")

(define (take thing)
  (move! thing me))

(define-user-command (take thing)
  "Moves thing to your inventory")

(define (drop thing)
  (move! thing (here)))

(define-user-command (drop thing)
  "Removes thing from your inventory and places it in the room
")

(define (put thing container)
  (move! thing container))

(define-user-command (put thing container)
  "Moves the thing from its current location and puts it in the container.")

(define (help)
  (for-each (λ (command-info)
              (begin (display (first command-info))
                     (newline)
                     (display (second command-info))
                     (newline)
                     (newline)))
            (all-user-commands)))

(define-user-command (help)
  "Displays this help information")

(define-user-command (go door)
  "Go through the door to its destination")

(define (check condition)
  (if condition
      (display-line "Check succeeded")
      (error "Check failed!!!")))

(define-user-command (check condition)
  "Throws an exception if condition is false.")



;;;
;;; ADD YOUR COMMANDS HERE!
;;;

(define-user-command (approach (person))
  "Go say hi to our friends")

(define-user-command (tap (person))
  "Wow everyone here is so nice.")

(define-user-command (view (the poster))
  "Admire artwork, such as the poster")

(define-user-command (open (the book))
  "Opens the book")

(define-user-command (close (the book))
  "Closes the book")

(define-user-command (read (the book))
  "Reads the book")

(define-user-command (unlock (lockbox) "password")
  "Try to unlock the lockbox using the specified password")


(define-user-command (unlock (kitchen-appliance))
  "Make sure the key is in your inventory to unlock the appliance")


(define-user-command (open (kitchen-appliance))
  "Will only open appliance if you have the key")

(define-user-command (cook (the grill) (food))
  "cook food with the grill in your kitchen")



(define-user-command (clean (the grill))
  "Clean the grill to use it")

(define-user-command (eat (food))
  "You can only eat cooked food")


(define-user-command (smack (the microwave))
  "Smack the microwave to make it work")

(define-user-command (heat (the microwave) (food))
  "heat food with the microwave in your kitchen")

(define-user-command (plug-in (the toaster-oven))
  "Need to plug in the toaster for it to work")

(define-user-command (toast (the toaster-oven) (food))
  "Toast food with the toaster oven in your kitchen")

(define-user-command (install-blade (the blender))
  "Need to install blade for blender to work")

(define-user-command (blend (the blender) food)
  "Make a smoothie using the blender")

(define-user-command (drink (the food))
  "You can only drink liquids that have been blended")

(define-user-command (insert-human-body (the human-body-grinder))
  "Put the human body in the grinder")

(define-user-command (grind (the human-body-grinder) (the human-body))
  "Grind the human body")

(define-user-command (spread (the human-body))
  "Spread the human body")

(define-user-command (approach (the button))
  "Go say hi to the button")

(define-user-command (press (the button))
  "Press the button, I have no clue what's going to happen.")


;;;
;;; THE GAME WORLD - FILL ME IN
;;;

;; start-game: -> void
;; Recreate the player object and all the rooms and things.


(define (start-game)
  ;; Fill this in with the rooms you want
  (local [(define starting-room (new-room "musty"))
          (define kitchen (new-room "kitchen looking"))
          (define (new-key location)
             (new-prop "key" "a key to the kitchen" location))
          (define (new-chicken location)
            (new-prop "chicken" "it's a raw chicken!" location))
          (define (new-poptart location)
            (new-prop "poptart" "it's a plain poptart!" location))
          (define (new-pizza location)
            (new-prop "pizza" "its a frozen pizza!" location))
          (define (new-banana location)
            (new-prop "banana" "its a boring banana!" location))
          (define (new-human-body location)
            (new-prop "human-body" "its a rotting human body!" location))

           ]
    (begin (set! me (new-person "" starting-room))
           ;; Add join commands to connect your rooms with doors
           (join! starting-room "trusty"
                  kitchen "musty")
           ;; Add code here to add things to your rooms
           (new-clown "joyful" starting-room)
           (new-book "dusty" starting-room)
           (new-chef "friendly" kitchen)
           (new-key (new-lockbox "rusty" "When shall we three meet again?" starting-room))
           (new-poster "inspirational cat" starting-room)
           (new-chicken (new-fridge "frosty" kitchen))
           (new-poptart (new-pantry "silly" kitchen))
           (new-pizza (new-freezer "chilly" kitchen))
           (new-banana (new-fruit-basket "straw" kitchen))
           (new-grill "amazing" kitchen)
           (new-toaster-oven "wonderful" kitchen)
           (new-microwave "macro" kitchen)
           (new-blender "sharp" kitchen)
           (new-human-body (new-human-body-storage "delicious" kitchen))
           (new-human-body-grinder "tasty" kitchen)
           (new-button "DO NOT PRESS" kitchen)
           
           
           
            
           (check-containers!)
           (void))))

;;;
;;; PUT YOUR WALKTHROUGHS HERE
;;;
(define-walkthrough win
  (view (the inspirational cat poster))
  (read (the dusty book))
  (open (the dusty book))
  (read (the dusty book))
  (take (the dusty book))
  (open (the rusty lockbox))
  (unlock (the rusty lockbox) "When shall we three meet again?")
  (open (the rusty lockbox))
  (take (within (the rusty lockbox) key))
  (go (the trusty door))
  (open (the frosty fridge))
  (unlock (the frosty fridge))
  (open (the frosty fridge))
  (take (within (the frosty fridge) chicken))
  (clean (the amazing grill))
  (cook (the amazing grill) (the chicken))
  (eat (the chicken))
  (plug-in (the wonderful toaster-oven))
  (open (the silly pantry))
  (unlock (the silly pantry))
  (open (the silly pantry))
  (take (within (the silly pantry) poptart))
  (toast (the wonderful toaster-oven) (the poptart))
  (eat (the poptart))
  (unlock (the chilly freezer))
  (open (the chilly freezer))
  (take (within (the chilly freezer) pizza))
  (smack (the macro microwave))
  (heat (the macro microwave) (the pizza))
  (eat (the pizza))
  (unlock (the straw fruit-basket))
  (open (the straw fruit-basket))
  (take (within (the straw fruit-basket) banana))
  (install-blade (the sharp blender))
  (blend (the sharp blender) (the banana))
  (drink (the banana))
  (unlock (the delicious human-body-storage))
  (take (within (the delicious human-body-storage) human-body))
  (insert-human-body (the tasty human-body-grinder))
  (grind (the tasty human-body-grinder) (the human-body))
  (spread (the human-body))
  (approach (the button))
  (press (the button)))



;;;
;;; UTILITIES
;;;

;; here: -> container
;; The current room the player is in
(define (here)
  (thing-location me))

;; stuff-here: -> (listof thing)
;; All the stuff in the room the player is in
(define (stuff-here)
  (container-accessible-contents (here)))

;; stuff-here-except-me: -> (listof thing)
;; All the stuff in the room the player is in except the player.
(define (stuff-here-except-me)
  (remove me (stuff-here)))

;; my-inventory: -> (listof thing)
;; List of things in the player's pockets.
(define (my-inventory)
  (container-accessible-contents me))

;; accessible-objects -> (listof thing)
;; All the objects that should be searched by find and the.
(define (accessible-objects)
  (append (stuff-here-except-me)
          (my-inventory)))

;; have?: thing -> boolean
;; True if the thing is in the player's pocket.
(define (have? thing)
  (eq? (thing-location thing)
       me))

;; have-a?: predicate -> boolean
;; True if the player as something satisfying predicate in their pocket.
(define (have-a? predicate)
  (ormap predicate
         (container-accessible-contents me)))

;; find-the: (listof string) -> object
;; Returns the object from (accessible-objects)
;; whose name contains the specified words.
(define (find-the words)
  (find (λ (o)
          (andmap (λ (name) (is-a? o name))
                  words))
        (accessible-objects)))

;; find-within: container (listof string) -> object
;; Like find-the, but searches the contents of the container
;; whose name contains the specified words.
(define (find-within container words)
  (find (λ (o)
          (andmap (λ (name) (is-a? o name))
                  words))
        (container-accessible-contents container)))

;; find: (object->boolean) (listof thing) -> object
;; Search list for an object matching predicate.
(define (find predicate? list)
  (local [(define matches
            (filter predicate? list))]
    (case (length matches)
      [(0) ((error "There's nothing like that here"))]
      [(1) (first matches)]
      [else (error "Which one?")])))

;; everything: -> (listof container)
;; Returns all the objects reachable from the player in the game
;; world.  So if you create an object that's in a room the player
;; has no door to, it won't appear in this list.
(define (everything)
  (local [(define all-containers '())
          ; Add container, and then recursively add its contents
          ; and location and/or destination, as appropriate.
          (define (walk container)
            ; Ignore the container if its already in our list
            (unless (member container all-containers)
              (begin (set! all-containers
                           (cons container all-containers))
                     ; Add its contents
                     (for-each walk (container-contents container))
                     ; If it's a door, include its destination
                     (when (door? container)
                       (walk (door-destination container)))
                     ; If  it's a thing, include its location.
                     (when (thing? container)
                       (walk (thing-location container))))))]
    ; Start the recursion with the player
    (begin (walk me)
           all-containers)))

;; print-everything: -> void
;; Prints all the objects in the game.
(define (print-everything)
  (begin (display-line "All objects in the game:")
         (for-each print-description (everything))))

;; every: (container -> boolean) -> (listof container)
;; A list of all the objects from (everything) that satisfy
;; the predicate.
(define (every predicate?)
  (filter predicate? (everything)))

;; print-every: (container -> boolean) -> void
;; Prints all the objects satisfying predicate.
(define (print-every predicate?)
  (for-each print-description (every predicate?)))

;; check-containers: -> void
;; Throw an exception if there is an thing whose location and
;; container disagree with one another.
(define (check-containers!)
  (for-each (λ (container)
              (for-each (λ (thing)
                          (unless (eq? (thing-location thing)
                                       container)
                            (error (description container)
                                   " has "
                                   (description thing)
                                   " in its contents list but "
                                   (description thing)
                                   " has a different location.")))
                        (container-contents container)))
            (everything)))

;; is-a?: object word -> boolean
;; True if word appears in the description of the object
;; or is the name of one of its types
(define (is-a? obj word)
  (let* ((str (if (symbol? word)
                  (symbol->string word)
                  word))
         (probe (name->type-predicate str)))
    (if (eq? probe #f)
        (member str (description-word-list obj))
        (probe obj))))

;; display-line: object -> void
;; EFFECT: prints object using display, and then starts a new line.
(define (display-line what)
  (begin (display what)
         (newline)
         (void)))

;; words->string: (listof string) -> string
;; Converts a list of one-word strings into a single string,
;; e.g. '("a" "red" "door") -> "a red door"
(define (words->string word-list)
  (string-append (first word-list)
                 (apply string-append
                        (map (λ (word)
                               (string-append " " word))
                             (rest word-list)))))

;; string->words: string -> (listof string)
;; Converts a string containing words to a list of the individual
;; words.  Inverse of words->string.
(define (string->words string)
  (string-split string))

;; add-a-or-an: (listof string) -> (listof string)
;; Prefixes a list of words with "a" or "an", depending
;; on whether the first word in the list begins with a
;; vowel.
(define (add-a-or-an word-list)
  (local [(define first-word (first word-list))
          (define first-char (substring first-word 0 1))
          (define starts-with-vowel? (string-contains? first-char "aeiou"))]
    (cons (if starts-with-vowel?
              "an"
              "a")
          word-list)))

;;
;; The following calls are filling in blanks in the other files.
;; This is needed because this file is in a different langauge than
;; the others.
;;
(set-find-the! find-the)
(set-find-within! find-within)
(set-restart-game! (λ () (start-game)))
(define (game-print object)
  (cond [(void? object)
         (void)]
        [(object? object)
         (print-description object)]
        [else (write object)]))

(current-print game-print)
   
;;;
;;; Start it up
;;;

(start-game)
(look)

