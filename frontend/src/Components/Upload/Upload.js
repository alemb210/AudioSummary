import React, { useState } from 'react';
import ReactDOM from 'react-dom';
import Button from '../Button/Button';
import './Upload.css';
import { FilePond, registerPlugin } from 'react-filepond';
import 'filepond/dist/filepond.min.css';
import Download from '../Download/Download';

function Upload() {
    const [files, setFiles] = useState([]);
    const [uploadedFileId, setUploadedFileId] = useState(null); //track state of uploaded file

    const generateFilename = (file) => {
        let timestamp = Date.now();
        let extension = file.name.split('.').pop();
        let name = file.name.split('.').slice(0, -1).join('.');
        return {filenameNoExt:`${name}_${timestamp}`, filename: `${name}_${timestamp}.${extension}`};
    }

    return (
        <div className="upload-card">
            <FilePond
                files={files}
                onupdatefiles={setFiles}
                allowMultiple={false}
                server={{
                    process: (fieldName, file, metadata, load, error, progress, abort) => {
                        const {filenameNoExt, filename} = generateFilename(file);
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
                                    setUploadedFileId(filenameNoExt); //update state to render download component
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
            {uploadedFileId && <div className="download-card"><Download fileId={uploadedFileId} /></div>}
        </div>
    );
}
export default Upload;