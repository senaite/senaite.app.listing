import { useEffect, useRef } from "react";

const ToastNotification = ({ id, message, title, onClose }) => {
    const toastRef = useRef(null);

    useEffect(() => {
        if (toastRef.current) {
          const toast = new window.bootstrap.Toast(toastRef.current);
          toast.show();
        }
    }, []);

    return (
        <div ref={toastRef}
             style={{width: "300px"}}
             className="toast fade show"
             role="alert"
             data-animation="true"
             data-autohide="false"
             data-delay="5000">
          <div className="toast-header">
            <strong className="mr-auto">{title}</strong>
            <button type="button" className="mr-2 mb-1 close" data-dismiss="toast" aria-label="Close" onClick={() => onClose(id)}>
              <span aria-hidden="true">&times;</span>
            </button>
          </div>
          <div className="toast-body">
            {message}
          </div>
        </div>
    );
};

export default ToastNotification;
