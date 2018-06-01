var data = new FormData();

data.append("", "/Users/abrahamsofer/indv/gephi/gephi-toolkit-demos/fcluster1.graphml");

 

var xhr = new XMLHttpRequest();

xhr.withCredentials = true;

 

xhr.addEventListener("readystatechange", function () {

  if (this.readyState === 4) {

    console.log(this.responseText);

  }

});

 

xhr.open("POST", "http://dsigdopreprod.doc.ic.ac.uk/api/CaveState/PostFile?serverPath=graphml");

xhr.setRequestHeader("cache-control", "no-cache");

xhr.setRequestHeader("postman-token", "60405eab-4727-6817-a05d-3e53c7385762");

 

xhr.send(data);

 