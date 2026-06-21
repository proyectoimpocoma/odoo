(function () {
    function digitsOnly(value) {
        return (value || "").replace(/\D/g, "");
    }

    function getFieldErrorElement(field) {
        var container = field.closest(".risk-vr-field") || field.closest(".risk-vr-extra-owner");
        var error;

        if (!container) {
            return null;
        }
        error = container.querySelector(".risk-vr-field-error");
        if (!error) {
            error = document.createElement("p");
            error.className = "risk-vr-field-error";
            if (field.id) {
                error.id = field.id + "-error";
                field.setAttribute("aria-describedby", error.id);
            }
            container.appendChild(error);
        }
        return error;
    }

    function setFieldError(field, message) {
        var error = getFieldErrorElement(field);

        field.setCustomValidity(message || "");
        field.classList.toggle("is-invalid", Boolean(message));
        field.setAttribute("aria-invalid", message ? "true" : "false");
        if (error) {
            error.textContent = message || "";
            error.hidden = !message;
        }
    }

    function validateRequired(field, label) {
        if (!field || field.disabled) {
            return true;
        }
        var valid = Boolean((field.value || "").trim());
        setFieldError(field, valid ? "" : label + " es obligatorio.");
        return valid;
    }

    function validatePattern(field, regexp, message, normalize) {
        var value;

        if (!field || field.disabled) {
            return true;
        }
        value = (field.value || "").trim();
        if (normalize === "digits") {
            value = digitsOnly(value).slice(0, Number(field.maxLength) > 0 ? Number(field.maxLength) : 99);
            field.value = value;
        } else if (normalize === "upper") {
            value = value.toUpperCase();
            field.value = value;
        }
        if (!value && !field.required) {
            setFieldError(field, "");
            return true;
        }
        if (!value && field.required) {
            setFieldError(field, "Este campo es obligatorio.");
            return false;
        }
        setFieldError(field, regexp.test(value) ? "" : message);
        return regexp.test(value);
    }

    function validateEmail(field, label) {
        return validatePattern(
            field,
            /^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$/,
            "Ingresa un correo valido para " + label + ".",
            null
        );
    }

    function validateMobile(field, label) {
        return validatePattern(
            field,
            /^3[0-9]{9}$/,
            "El " + label + " debe tener 10 digitos e iniciar por 3.",
            "digits"
        );
    }

    function validateRadioGroup(groupName, message) {
        var radios = Array.prototype.slice.call(document.querySelectorAll('input[name="' + groupName + '"]'));
        var checked = radios.some(function (radio) { return radio.checked; });
        var row = radios.length ? radios[0].closest(".risk-vr-radio-row, .risk-vr-anticipos, .risk-vr-declare-row") : null;
        var error;

        radios.forEach(function (radio) {
            radio.setCustomValidity(checked ? "" : message);
            radio.setAttribute("aria-invalid", checked ? "false" : "true");
        });
        if (row) {
            error = row.querySelector(".risk-vr-field-error");
            if (!error) {
                error = document.createElement("p");
                error.className = "risk-vr-field-error";
                row.appendChild(error);
            }
            error.textContent = checked ? "" : message;
            error.hidden = checked;
        }
        return checked;
    }

    function firstInvalid(current, candidate) {
        return current || candidate;
    }

    function validateVehicleForm(form) {
        var valid = true;
        var first = null;
        var field;

        [
            ["form_date", "La fecha"],
            ["satellite_company", "La empresa de rastreo satelital"],
            ["satellite_user", "El usuario de la cuenta satelital"],
            ["satellite_password", "La clave de la cuenta satelital"],
        ].forEach(function (item) {
            field = document.getElementById(item[0]);
            if (!validateRequired(field, item[1])) {
                valid = false;
                first = firstInvalid(first, field);
            }
        });

        field = document.getElementById("vehicle_plate");
        if (!validatePattern(field, /^[A-Z]{3}[0-9]{3}$/, "La placa debe tener formato ABC123.", "upper")) {
            valid = false;
            first = firstInvalid(first, field);
        }

        field = document.getElementById("semi_trailer_plate");
        if (field && !field.disabled && !validatePattern(field, /^[A-Z][0-9]{5}$/, "La placa del semi/remolque debe tener formato A12345.", "upper")) {
            valid = false;
            first = firstInvalid(first, field);
        }

        field = document.getElementById("satellite_url");
        if (field) {
            if (!validateRequired(field, "La URL de rastreo satelital")) {
                valid = false;
                first = firstInvalid(first, field);
            } else if (!/^https?:\/\/.+/i.test(field.value.trim())) {
                setFieldError(field, "La URL debe iniciar con http:// o https://.");
                valid = false;
                first = firstInvalid(first, field);
            } else {
                setFieldError(field, "");
            }
        }

        return { valid: valid, first: first };
    }

    function documentPatternForType(type) {
        return type === "nit" ? /^[0-9]{6,10}(-[0-9])?$/ : /^[0-9]{6,10}$/;
    }

    function documentMessageForType(type, label) {
        return type === "nit"
            ? "El NIT de " + label + " debe tener formato 123456789 o 123456789-0."
            : "La cedula de " + label + " debe tener entre 6 y 10 digitos.";
    }

    function validateOwnerDocument(typeField, numberField, label) {
        var type = typeField ? typeField.value : "";

        if (!validateRequired(typeField, "El tipo de documento de " + label)) {
            return false;
        }
        return validatePattern(numberField, documentPatternForType(type), documentMessageForType(type, label), null);
    }

    function validateExtraOwners() {
        var sameOwner = document.getElementById("same_owner_on_license");
        var list = document.getElementById("extra-owners-list");
        var rows = list ? Array.prototype.slice.call(list.querySelectorAll("[data-extra-owner-row='1']")) : [];
        var valid = true;
        var first = null;
        var container = document.querySelector(".risk-vr-extra-owners");
        var containerError;

        if (!sameOwner || sameOwner.value !== "no") {
            return { valid: true, first: null };
        }
        if (!rows.length) {
            if (container) {
                containerError = container.querySelector(".risk-vr-field-error");
                if (!containerError) {
                    containerError = document.createElement("p");
                    containerError.className = "risk-vr-field-error";
                    container.appendChild(containerError);
                }
                containerError.textContent = "Agrega al menos un propietario adicional.";
                containerError.hidden = false;
            }
            return { valid: false, first: document.getElementById("add-extra-owner") };
        }
        if (container) {
            containerError = container.querySelector(":scope > .risk-vr-field-error");
            if (containerError) {
                containerError.hidden = true;
            }
        }

        rows.forEach(function (row) {
            var name = row.querySelector('input[name="extra_owner_name"]');
            var type = row.querySelector('select[name="extra_owner_document_type"]');
            var number = row.querySelector('input[name="extra_owner_document_number"]');
            var phone = row.querySelector('input[name="extra_owner_phone"]');
            var email = row.querySelector('input[name="extra_owner_email"]');

            if (!validateRequired(name, "El nombre del propietario adicional")) {
                valid = false;
                first = firstInvalid(first, name);
            }
            if (!validateOwnerDocument(type, number, "propietario adicional")) {
                valid = false;
                first = firstInvalid(first, number || type);
            }
            if (!validateMobile(phone, "celular del propietario adicional")) {
                valid = false;
                first = firstInvalid(first, phone);
            }
            if (!validateEmail(email, "el propietario adicional")) {
                valid = false;
                first = firstInvalid(first, email);
            }
        });
        return { valid: valid, first: first };
    }

    function validateOwnerForm(form) {
        var valid = true;
        var first = null;
        var extraResult;

        [
            ["owner_name", "El nombre del propietario"],
            ["owner_address", "La direccion del propietario"],
            ["owner_city", "La ciudad del propietario"],
            ["owner_neighborhood", "El barrio del propietario"],
        ].forEach(function (item) {
            var field = document.getElementById(item[0]);
            if (!validateRequired(field, item[1])) {
                valid = false;
                first = firstInvalid(first, field);
            }
        });

        if (!validateOwnerDocument(
            document.getElementById("owner_document_type"),
            document.getElementById("owner_document_number"),
            "propietario"
        )) {
            valid = false;
            first = firstInvalid(first, document.getElementById("owner_document_number"));
        }
        if (!validateMobile(document.getElementById("owner_phone"), "celular del propietario")) {
            valid = false;
            first = firstInvalid(first, document.getElementById("owner_phone"));
        }
        if (!validateEmail(document.getElementById("owner_email"), "el propietario")) {
            valid = false;
            first = firstInvalid(first, document.getElementById("owner_email"));
        }
        if (!validateRadioGroup("advance_payment_to", "Debes indicar a quien se autoriza el pago de anticipos.")) {
            valid = false;
            first = firstInvalid(first, document.querySelector('input[name="advance_payment_to"]'));
        }

        extraResult = validateExtraOwners();
        if (!extraResult.valid) {
            valid = false;
            first = firstInvalid(first, extraResult.first);
        }
        return { valid: valid, first: first };
    }

    function initRiskStepValidation() {
        var form = document.querySelector(".risk-vr-form");

        if (!form) {
            return;
        }
        form.addEventListener("input", function (event) {
            var field = event.target;
            if (field.id === "vehicle_plate" || field.id === "semi_trailer_plate") {
                field.value = field.value.toUpperCase();
            }
            if (field.id === "owner_phone" || field.name === "extra_owner_phone") {
                field.value = digitsOnly(field.value).slice(0, 10);
            }
        });
        form.addEventListener("change", function (event) {
            if (event.target.name === "advance_payment_to") {
                validateRadioGroup("advance_payment_to", "Debes indicar a quien se autoriza el pago de anticipos.");
            }
        });
        form.addEventListener("submit", function (event) {
            var result = { valid: true, first: null };

            if (document.getElementById("vehicle_plate")) {
                result = validateVehicleForm(form);
            } else if (document.getElementById("owner_document_number")) {
                result = validateOwnerForm(form);
            }
            if (!result.valid) {
                event.preventDefault();
                event.stopPropagation();
                if (result.first && typeof result.first.focus === "function") {
                    result.first.focus();
                }
                if (form.reportValidity) {
                    form.reportValidity();
                }
            }
        });
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", initRiskStepValidation);
    } else {
        initRiskStepValidation();
    }
}());
