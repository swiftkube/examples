function openModal() {
	const modal = document.getElementById("modal");
	modal.classList.add("is-active");
}

function cancelModal() {
	const modal = document.getElementById("modal");
	modal.classList.remove("is-active");
	document.getElementById("create-object-form").reset();
}

function showToast(style, title, message) {
	const toast = document.getElementById("toast");
	toast.style.display = "block";

	const toastMessage = document.getElementById("toast-message");
	toastMessage.classList.add(style);

	const header = toast.querySelector(".message-header p");
	const body = toast.querySelector(".message-body");
	header.innerHTML = title;
	body.innerHTML = message;

	setTimeout(function() { 
		closeToast();
	}, 3000);
}

function closeToast() {
	const toast = document.getElementById("toast");
	toast.style.display = "none";
	
	const toastMessage = document.getElementById("toast-message");
	toastMessage.classList.remove("is-success");
	toastMessage.classList.remove("is-danger");

	const header = toast.querySelector(".message-header p");
	const body = toast.querySelector(".message-body");
	header.innerHTML = "";
	body.innerHTML = "";
}

function followLogs(namespace, pod, container) {
	const logs = document.getElementById("pod-logs");
	logs.innerHTML = "";
	logs.style.display = "block";

	const url = new URL(`/logs/${namespace}/${pod}/${container}`, window.location.href);
	url.protocol = url.protocol.replace('http', 'ws');

	const socket = new WebSocket(url);
	socket.onmessage = function (event) {
		const line = document.createElement("div");
		line.classList.add("preformatted");
		line.textContent = event.data;
		logs.appendChild(line);
	};
}

function initEditor() {
	const editor = ace.edit("object-yaml-editor");
	editor.session.setMode("ace/mode/yaml");
	editor.session.setUseWorker(false);
	editor.setOptions({
		showInvisibles: true,
		useSoftTabs: true,
		tabSize: 2
	});	
}

function initForm() {
	const form = document.getElementById("create-object-form");
	form.onsubmit = function(event) {
		event.preventDefault();

		const namespace = document.getElementById("object-namespace").value;
		const editor = ace.edit("object-yaml-editor");
		const yaml = editor.getValue();

		const xhr = new XMLHttpRequest();
		xhr.open("POST", `/namespace/${namespace}`, true);
		xhr.setRequestHeader('Content-Type', 'application/json; charset=UTF-8');
		xhr.onreadystatechange = function() {
			if (xhr.readyState == XMLHttpRequest.DONE) {
				if (xhr.status >= 200 && xhr.status < 300) {
					showToast("is-success", "Success", "Resource created");
					cancelModal();
				} else {
					showToast("is-danger", `Status: ${xhr.status}`, xhr.responseText);
				}
			}
		};

		xhr.send(yaml);
	}
}

initEditor();
initForm();
