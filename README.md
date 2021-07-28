# thoughts 
* This is not meant to be understood. Just reminders to self. 

* Interface to different GUI apps. Handled via plugins. 
	* zim
	* Google calendar
	* Google contacts
	* Our grocery
	* Terminal
	* Web
	* The brain?
* A central "brain" accessed via REST from GUI apps
* Main components
	* Node
		* Consist of
			* Type
			* Name
			* Note(s) ?
			* Tag(s)?
			* Time stamps
			* List of attributes
	* Relation
		* Between two nodes
	* Attribute
		* A node
		* A base type property
		* A set of nodes
		* An array (ordered) of nodes
	* Base type properties
		* String
		* Integer
		* Date
		* Float 
		* ...
* Node and Relation maybe based on same "super class"
* Information might be stored in different places. Handled via plugins.
	* Google contacts, calendars, tasks
	* zim
	* Our grocery
	* Via REST API's 
	* ...
* Will have to consider a possible difference of related nodes versus attributes/properties. 
	- Might have to differ between a property of a node (object) and its relation to other nodes. 
	- But where draw the line. 
	- Nice to be able to share also properties by using "link predicates". Makes it easier to search and back link. 
* Can there be three types of properties:
	- A completely local one, ex "age" (typed primitive, stored in node). Indexed.
	- One that can be shared by other nodes, like a year, "1959". (typed primitive, stored in node). Indexed. 
	- Relations to other nodes. Link to Other Node. 
