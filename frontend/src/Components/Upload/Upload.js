import React, { useState } from 'react';
import ReactDOM from 'react-dom';
import Button from '../Button/Button';
import './Upload.css';

import { FilePond, registerPlugin } from 'react-filepond';
import 'filepond/dist/filepond.min.css';

function Upload() {
    const [files, setFiles] = useState([]);

    const generateFilename = (file) => {
        let timestamp = Date.now();
        let extension = file.name.split('.').pop();
        let name = file.name.split('.').slice(0, -1).join('.');
        return `${name}_${timestamp}.${extension}`;
    }

    // return (
    //     <div className="upload-card">
    //         <FilePond 
    //             files={files}
    //             onupdatefiles={setFiles}
    //             allowMultiple={false}
    //             filename = {generateFilename}
    //             server={{
    //                 url: 'https://h820u2bos4.execute-api.us-east-1.amazonaws.com/dev/{filename}', // API Gateway invoke URL
    //                 process: {
    //                     method: 'PUT',
    //                     headers: {
    //                         'Content-Type': 'multipart/form-data',
    //                     },
    //                     withCredentials: false,
    //                 },
    //             }}
    //             name="file"
    //             labelIdle='Drag & Drop your file or <span class="filepond--label-action">Browse</span>'
    //         />
    //     </div>
    // );


    return (
        <div className="upload-card">
            <FilePond
                files={files}
                onupdatefiles={setFiles}
                allowMultiple={false}
                server={{
                    process: (fieldName, file, metadata, load, error, progress, abort) => {
                        const filename = generateFilename(file);
                        const url = `https://h820u2bos4.execute-api.us-east-1.amazonaws.com/dev/${filename}`;

                        const formData = new FormData();
                        formData.append(fieldName, file);

                        fetch(url, {
                            method: 'PUT',
                            body: formData,
                            headers: {
                                'Content-Type': 'multipart/form-data',
                            },
                        })
                            .then(response => {
                                if (response.ok) {
                                    load(response.text());
                                } else {
                                    error('Upload failed');
                                }
                            })
                            .catch(() => error('Upload failed'));

                        return () => abort();
                    },
                }}
                name="file"
                labelIdle='Drag & Drop your file or <span class="filepond--label-action">Browse</span>'
            />
        </div>
    );
}

//Next: Add filetype validation and disable instant uploads (use button component instead)

export default Upload;