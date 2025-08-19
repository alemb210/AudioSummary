// import logo from '../../logo.svg';
import './App.css';
import Upload from '../Upload/Upload';

function App() {
  return (
    <div className="App">
      <header className="App-header">
        {/* <img src={logo} className="App-logo" alt="logo" /> */}
        <p>
          Upload an audio file to be summarized!
        </p>
        <Upload />
      </header>
    </div>
  );
}

export default App;
