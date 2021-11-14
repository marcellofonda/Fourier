using DelimitedFiles
using Plots
using CUDA
CUDA.allowscalar(false)
import Base.+
import Base.*

# PARAMETRI PERSONALIZZABILI

# Quanti termini della serie di Fourier si vogliono calcolare
const grado = 90
# Dove sono salvate le coordinate dei punti che si vogliono disegnare
path="coordinate.csv"
# Definisce l'intervallo [-L,L] dominio di definizione della curva parametrizzata.
# Abbastanza indifferente io credo.
const L=2
# Quanti istanti di tempo saltare nel calcolo dell'Animazione
# (influenza la qualità del disegno e la scattosità dell'animaz.)
const skip = 5
# Quanti frame saltare nella creazione dell'Animazione
# (influenza la "scattosità" dell'animazione)
const skipplots = 0
#Il numero di frame al secondo del risultante GIF
const fps = 30

#FUNZIONI

# Calcola l'integrale numerico sul dominio [inizio, fine] della funzione
# definita dai punti dell'array, considerati come immagini di punti equispaziati
# nell'intervallo [inizio,fine].
function integra(inizio, fine, arr)
    N=size(arr,1)
    temp=Array(arr)
    h=(fine-inizio)/N
    integrale=sum(arr)
    integrale -= (first(temp)+last(temp))/2
    integrale *= h
end

# Operazioni tra funzioni per rendere le funzioni uno spazio vettoriale
+(f::Function, g::Function)= (x...) -> f(x...)+g(x...)
*(a,f::Function)= (x...) -> a * f(x...)



# PROGRAMMA VERO E PROPRIO

# Scegli il backend per il pacchetto Plots (comando tecnico per poter disegnare)
gr()

println("Apro il file e leggo le coordinate...")

# Apri il file e leggi i valori come Float64 separati da virgole.
# a dovrebbe risultare una matrice con gli elementi del file, intabellati
# come nel file
inpu=open(path, "r")
a=readdlm(inpu,',', Float64)
println("File aperto e coordinate lette con successo!")

# Salva le coordinate come numeri complessi su GPU, calcola quanti sono e
# Calcola i corrispondenti punti equispaziati (controimmagini)
coord = CuArray{ComplexF64,1}(complex.(a[:,1],a[:,2]))
N=size(coord,1)
t=CuArray{Float64,1}(-L:(2L/(N-1)):L)



println("Inizializzo la base di Fourier e calcolo i coefficienti...")
# Questo sarà del tipo n=[0,1,-1,2,-2,...]
n=[((-1)^i)*(i÷2) for i in 1:grado]
# La "base" di Fourier: un insieme di funzioni del tipo e^{πkix/L}/L, con
# k che varia dentro n. Notare che la "base" è ortonormale per
# ⟨f,g⟩ := ∫fg
base= [ x -> exp(π * im * k * x / L)/L for k in n]

# Calcola i coefficienti dell'espansione usando il "prodotto scalare"
# α_k = ⟨e_k,f⟩
# NOTA teorica: Questo non è un prodotto scalare in senso complesso,
# perché è simmetrico e non hermitiano. Bisognerebbe cambiare il segno
# dell'esponenziale, ma siccome ∀ n, consideriamo anche -n, un po' ce
# ne freghiamo e funziona comunque.
α=[integra(-L, L, h.(t) .* coord) for h in base]

println("Coefficienti ottenuti con successo!")

# Variabile in cui salvare il percorso disegnato dalla funzione approssimante
percorso=ComplexF64[]

# Array con le funzioni di base, ciascuna moltiplicata per il suo coefficiente
# di Fourier
g = α .* base

# Array con le approssimazioni successive, all'aumentare del grado
f = [sum(g[1:i]) for i in 1:grado]
pushfirst!(f, x -> 0+0im)

println("Calcolo l'animazione...")
@time anim = @animate for tempo in Array(vcat(t,t))[1:(skip+1):end]
    # Disegna l'origine
    scatter([0+0im],aspect_ratio=1, legend=false);

    # Commentare se non si vuole vedere il disegno originale
    #plot!(Array{ComplexF64}(coord));

    # Per ogni successiva approssimazione, disegna il cerchio (epiciclo)
    # su cui ruota l'ultimo raggio e il raggio stesso. Il risultato è
    # un "braccio" formato da un numero di raggi pari al grado, ciascuno
    # con il corrispondente cerchio su cui spaziare.
    for i in 1:grado
        # Il cerchio su cui ruota l'ultimo raggio della i-esima approssimazione
        gnam = g[i].(t) .+ f[i](tempo)
        plot!(Array{ComplexF64}(gnam));
        x1=f[i](tempo)
        x2=f[i+1](tempo)
        # Disegna il raggio della i-esima approssimazione
        plot!([x1, x2]);
    end
    # Aggiungi alla traiettoria l'estremo finale dell'ultimo raggio
    push!(percorso, f[grado+1](tempo))
    # Disegna la traiettoria tracciata finora
    plot!(percorso);
end every (skipplots+1)
println("Animazione calcolata con successo nel tempo sopra specificato, procedo a salvare su GIF...")
# Salva l'animazione su GIF, con lo stesso nome del file da cui vengono le
# coordinate
gif(anim, "$path.gif", fps=fps)
println("GIF salvata con successo!")
