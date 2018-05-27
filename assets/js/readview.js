function toggle_translated_info_delegate(element){
	return function(){
		toggle_translated_info(element);
	}
}

function toggle_translated_info(parent){
	var children = parent.getElementsByClassName("phoenix_translated_additional_info");
	for (var i = 0; i < children.length; ++i) {
		var node = children[i];
		if (node.style.display == "block"){
			node.style.display = "none";
		} else {
			node.style.display = "block";
		}
	}
}

const App = {
  init() {
    var elements = document.getElementsByClassName("phoenix_translated_value");
	for (var i = 0; i < elements.length; ++i){
		elements[i].addEventListener("click", toggle_translated_info_delegate(elements[i]));
	}
  }
};

module.exports = App;