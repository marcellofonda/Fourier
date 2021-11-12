using DelimitedFiles
using Plots
import Base.+
import Base.*

grado = 10
path="cuore.csv"


function integra(inizio, fine, arr)
    N=size(arr,1)
    h=(fine-inizio)/N
    integrale=sum(arr[2:(N-1)])
    integrale += (arr[1]+last(arr))/2
    integrale *= h
end

+(f::Function, g::Function)= (x...) -> f(x...)+g(x...)
*(a,f::Function)= (x...) -> a * f(x...)

#Scegli il backend per il pacchetto Plots e approfitta per compilare
# @time
inutile = @time gr()
println("Apro il file e leggo le coordinate...")
inpu=open(path, "r")
a=readdlm(inpu,',', Float64)
coord = complex.(a[:,1],a[:,2])
println("File aperto e coordinate lette con successo!")
#plot(traiettoria)

L=2
N=size(coord,1)

println("Inizializzo la base di Fourier e calcolo i coefficienti...")
n=[((-1)^i)div(i,2) for i in 0:grado]
base= [x -> exp(π*im*i*x/L) for i in n]
t=-L:(2L/(N-1)):L

α=[integra(-L,L, g.(t) .* coord) for g in base]
α[1]=integra(-L,L,coord)/2L

println("Coefficienti ottenuti con successo!")

percorso=ComplexF64[]


f = x -> (0+0im)
println("Calcolo l'animazione...")
@time anim = @animate for tempo in vcat(t,t)
    global f = x -> (0+0im)
    scatter([0+0im],aspect_ratio=1)
    #plot!(coord)
    for i in 1:(grado+1)
        local g = α[i] * base[i]
        gnam = g.(t).+f(tempo)
        plot!(gnam)
        x1=f(tempo)
        global f += g
        x2=f(tempo)
        plot!([x1, x2])

    end

    push!(percorso, f(tempo))
    #println(percorso)
    plot!(percorso)
end #every 5
println("Animazione calcolata con successo nel tempo sopra specificato, procedo a salvare su GIF...")
gif(anim, "animazione.gif", fps=30)
println("GIF salvata con successo!")
